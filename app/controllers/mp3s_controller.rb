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
    $redis.get("cur_cast")
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
    state = params[:state_local]
    playlist_md5 = Digest::MD5.hexdigest(JSON.dump(playlist))
    $redis.hset("cur_playlist", cur_cast, playlist_md5)

    if state[:shuffle] == "on"
      clicked = playlist.shift # We want the clicked mp3 to play first, all else is shuffled
      playlist.shuffle!
      playlist.unshift(clicked)
    end

    #ActionCable.server.broadcast "state", { sent_by: 'Paul', body: 'This is a cool chat app.' }

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
        Device.play_url(mp3[:url])
        sleep(3)

        def wait_for_it(str, playlist_md5)
          player_state = ""
          while (player_state != str)
            player_state = Device.player_status()
            Thread.exit if $redis.hget("cur_playlist", cur_cast) != playlist_md5 || player_state == "UNKNOWN"  # A user played a different playlist or cast went down
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

        # Wait for device to go from playing/paused/idle to buffering
        if wait_for_it("BUFFERING", playlist_md5)
          if wait_for_it("IDLE", playlist_md5)
            # If we get here the song played its entire length. Move on to next song in playlist.
            @index += 1
          end
        end

        if state[:repeat] == "one"
          @index = 0
        end
        if state[:repeat] == "all" && @index >= playlist.length
          @index = 0
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