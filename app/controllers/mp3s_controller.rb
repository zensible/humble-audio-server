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

  def play
    urls = params[:urls]
    playlist_md5 = Digest::MD5.hexdigest(JSON.dump(urls))
    $redis.set("cur_playlist", playlist_md5)

    # What's happening here since it's non-obvious:
    #
    # pychromecast doesn't support queuing mp3s, so we if we want to sequentially play a playlist we have to implement the queue ourselves
    #
    # It would be easy to play the URLs in sequence, but Rails needs a response or the browser will time out.
    # So, we fork the process and tell Rails we've begun playing
    # 
    #child_pid = fork do
    Thread.new do
      urls.each do |url|
        Device.play_url(url)

        player_state = ""
        cnt = 0
        while (player_state != "BUFFERING")
          player_state = Device.player_status()
          Thread.exit if $redis.get("cur_playlist") != playlist_md5  # A user played a different playlist
          sleep(0.25)
        end

        player_state = "BUFFERING"
        cnt = 0
        while (player_state != "IDLE") # == "PLAYING" || player_state == "PAUSED" || player_state == "BUFFERING"
          player_state = Device.player_status()
          Thread.exit if $redis.get("cur_playlist") != playlist_md5  # A user played a different playlist
          sleep(0.5)
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