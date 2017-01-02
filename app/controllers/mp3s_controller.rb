class Mp3sController < ApiController

  skip_before_action :verify_authenticity_token, :only => [:play]

  def get
    mode = params[:mode]
    mp3s = get_media_by_mode(mode)
    render :json => mp3s
  end

  def cur_cast
    $redis.get("cur_cast")
  end

  def play
    id = params[:id]
    url = params[:url]
    Device.play_url(url)
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