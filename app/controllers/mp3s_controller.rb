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
    id = params[:id]
    url = params[:url]
    Device.play_url(url)

    #child_pid = fork do
    #  sleep 10
    #  Device.play_url("http://192.168.0.103:3000/audio/music/!Dance%20Mix/05%20-%20Setting%20Sun.mp3")
    #  exit
    #end

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