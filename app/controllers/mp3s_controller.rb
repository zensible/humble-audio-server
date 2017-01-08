class Mp3sController < ApiController

  skip_before_action :verify_authenticity_token, :only => [:play]

  def get
    mode = params[:mode]
    id = params[:id]

    folders = []
    playlists = []

    if mode == "music"
      mp3s = Mp3.where("mode = 'music' AND folder_id = '#{id}'").order("track_nr, artist, album, title, filename")
    elsif mode == "white-noise"
      mp3s = Mp3.where("mode = 'white-noise'").order("title")
    end

    render :json => mp3s
  end

  def get_folders
    render :json => Folder.all.order("basename")
  end

  #def cur_cast
  #  $redis.get("cur_cast")  # UUID of cast
  #end

  def next
    $redis.hset("playlist_move", params[:cast_uuid], "1")
    render :json => { success: true }
  end

  def prev
    $redis.hset("playlist_move", params[:cast_uuid], "-1")
    render :json => { success: true }
  end

  def play
    playlist = params[:playlist]
    state_local = params[:state_local]
    cast_uuid = params[:state_local][:cast_uuid]

    @entry = {
      cast_uuid: cast_uuid,
      mode: state_local[:mode],
      folder_id: state_local[:folder_id],
      radio_station: state_local[:radio_station]
    }

    playlist_md5 = Digest::MD5.hexdigest(JSON.dump(playlist))
    $redis.hset("cur_playlist", cast_uuid, playlist_md5)

    if state_local[:shuffle] == "on"
      clicked = playlist.shift # We want the clicked mp3 to play first, all else is shuffled
      playlist.shuffle!
      playlist.unshift(clicked)
    end

    buffering_pause = 3.0  # Magic number here: number of seconds to wait for device to go from buffering to playing. We could use the wait_for_device_status() function, but sadly the device starts playing about 1s before the status updates to PLAYING so this isn't an option.

    @device = Device.new(cast_uuid)

    # What's happening here since it's non-obvious:
    #
    # pychromecast doesn't support queuing mp3s, so we if we want to sequentially play a playlist we have to implement the queue ourselves
    #
    # It would be easy to play the URLs in sequence, waiting for each one to complete, but Rails needs a response or the browser will time out.
    # So, we fork the process and do the sequential play in the background.
    # 
    Thread.abort_on_exception=true
    Thread.new do
      @index = 0
      while (@index >= 0 && @index < playlist.length)
        puts "Playlist index: #{@index}"
        mp3 = playlist[@index]

        # Notify all web users that we just started playing the mp3 on the given cast
        def play_start(cast_uuid, mp3)
          puts "START"
          @entry[:mp3_id] = mp3[:id]
          @entry[:mp3_url] = mp3[:url]

          state_shared = JSON.load($redis.get("state_shared") || "[]")
          updated = []
          state_shared.each do |st|
            updated.push(st) unless st["cast_uuid"] == cast_uuid
          end
          @entry[:player_num] = updated.length
          updated.push(@entry)
          str = JSON.dump(updated)
          $redis.set("state_shared", str)
          ActionCable.server.broadcast "state", str
        end

        def play_stop(cast_uuid)
          puts "STOP"
          state_shared = JSON.load($redis.get("state_shared") || "[]")
          updated = []
          state_shared.each do |st|
            updated.push(st) unless st["cast_uuid"] == cast_uuid
          end
          str = JSON.dump(updated)
          $redis.set("state_shared", str)
          ActionCable.server.broadcast "state", str
          Thread.exit
          #abort "done"
        end

        #Device.play_url(mp3[:url])
        @device.play_url(mp3[:url])
        sleep(0.5)
        play_start(cast_uuid, mp3)
        sleep(buffering_pause - 0.5)

        def wait_for_device_status(str, playlist_md5, cast_uuid)
          Rails.logger.info "(((( STR: [#{str}])))"
          player_state = ""
          while (player_state != str)
            player_state = @device.player_status()
            Rails.logger.info "(((( player_state: [#{player_state}])))"
            cast_state = @device.cast_status
            play_stop(cast_uuid) if $redis.hget("cur_playlist", cast_uuid) != playlist_md5 || player_state == "UNKNOWN"  # A user played a different playlist for this cast or cast went down
            mov = $redis.hget("playlist_move", cast_uuid)
            if !mov.blank?
              $redis.hset("playlist_move", cast_uuid, "")
              @index += mov.to_i  # Either forward or back in playlist (1 or -1)
              return false
            end
            sleep(0.5) # Poll device every half second
          end
          return true
        end

        # Wait for device to go from playing/paused/idle to buffering
        if wait_for_device_status("BUFFERING", playlist_md5, cast_uuid)
          if wait_for_device_status("IDLE", playlist_md5, cast_uuid)
            # If we get here the song played its entire length. Move on to next song in playlist.
            @index += 1
          end
        end

        if state_local[:repeat] == "one"
          @index = 0
        end
        if @index >= playlist.length
          if state_local[:repeat] == "all"
            @index = 0
          else
            play_stop(cast_uuid)
          end
        end
      end
    end
    sleep(buffering_pause)
    render :json => { success: true }
  end

  def stop
    cast_uuid = params[:cast_uuid]
    dev = Device.new(cast_uuid)
    dev.stop()
    render :json => { success: true }
  end

  def pause
    cast_uuid = params[:cast_uuid]
    dev = Device.new(cast_uuid)
    dev.pause()
    render :json => { success: true }
  end

  def resume
    cast_uuid = params[:cast_uuid]
    dev = Device.new(cast_uuid)
    dev.resume()
    render :json => { success: true }
  end

  def refresh
    mode = params[:mode]

    stats = Sync.refresh(mode)
    render :json => stats
  end

end