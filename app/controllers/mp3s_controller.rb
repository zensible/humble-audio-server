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

  def cur_cast
    $redis.get("cur_cast")  # UUID of cast
  end

  def next
    $redis.set("playlist_move", "1")
    render :json => { success: true }
  end

  def prev
    $redis.set("playlist_move", "-1")
    render :json => { success: true }
  end

  def play
    playlist = params[:playlist]
    state_local = params[:state_local]
    cast_uuid = cur_cast

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

    # What's happening here since it's non-obvious:
    #
    # pychromecast doesn't support queuing mp3s, so we if we want to sequentially play a playlist we have to implement the queue ourselves
    #
    # It would be easy to play the URLs in sequence, waiting for each one to complete, but Rails needs a response or the browser will time out.
    # So, we fork the process and do the sequential play in the background.
    # 
    #Thread.abort_on_exception=true
    Thread.new do
      @index = 0
      while (@index >= 0 && @index < playlist.length)
        puts "Playlist index: #{@index}"
        mp3 = playlist[@index]

        def play_start(cast_uuid, mp3)
          puts "START"
          @entry[:mp3_id] = mp3[:id]
          @entry[:mp3_url] = mp3[:url]

          state_shared = JSON.load($redis.get("state_shared") || "[]")
          updated = []
          state_shared.each do |st|
            updated.push(st) unless st["cast_uuid"] == cast_uuid
          end
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
        end

        Device.play_url(mp3[:url])
        print "001"
        sleep(3)
        play_start(cast_uuid, mp3)
        print "002"

        def wait_for_it(str, playlist_md5, cast_uuid)
          player_state = ""
          while (player_state != str)
            player_state = Device.player_status()
            puts "aaa"
            play_stop(cast_uuid) if $redis.hget("cur_playlist", cast_uuid) != playlist_md5 || player_state == "UNKNOWN"  # A user played a different playlist or cast went down
            puts "bbb"
            mov = $redis.get("playlist_move")
            if !mov.blank?
              $redis.set("playlist_move", "")
              @index += mov.to_i  # Either forward or back in playlist (1 or -1)
              return false
            end
            sleep(0.5)
          end
          return true
        end

        print "003"
        # Wait for device to go from playing/paused/idle to buffering
        if wait_for_it("BUFFERING", playlist_md5, cast_uuid)
        print "004"
          if wait_for_it("IDLE", playlist_md5, cast_uuid)
            # If we get here the song played its entire length. Move on to next song in playlist.
            @index += 1
          end
        end

        print "005"
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
    sleep(3)
    render :json => { success: true }
  end

  def stop
    Device.stop()
    render :json => { success: true }
  end

  def pause
    Device.pause()
    render :json => { success: true }
  end

  def resume
    Device.resume()
    render :json => { success: true }
  end

  def refresh
    mode = params[:mode]

    stats = Sync.refresh(mode)
    render :json => stats
  end

end