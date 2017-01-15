class Mp3sController < ApiController

  skip_before_action :verify_authenticity_token, :only => [:play]

  def get
    mode = params[:mode]
    id = params[:id]

    folders = []
    playlists = []

    if mode == "music"
      mp3s = Mp3.where("mode = 'music' AND folder_id = '#{id}'").order("track_nr, artist, album, title, filename")
    elsif mode == "spoken"
      mp3s = Mp3.where("mode = 'spoken' AND folder_id = '#{id}'").order("track_nr, artist, album, title, filename")
    elsif mode == "white-noise"
      mp3s = Mp3.where("mode = 'white-noise'").order("title")
    end

    render :json => mp3s
  end

  def get_folders
    mode = params[:mode]
    #folder_id = params[:folder_id]

    render :json => Folder.all.order("basename").where("mode = '#{mode}'")
  end

  #def cur_cast
  #  $redis.get("cur_cast")  # UUID of cast
  #end

  def next
    $redis.hset("thread_command", params[:cast_uuid], "next")
    render :json => { success: true }
  end

  def prev
    $redis.hset("thread_command", params[:cast_uuid], "prev")
    render :json => { success: true }
  end

  def play
    playlist_params = params[:playlist]
    playlist = []
    playlist_params.each do |pl|
      playlist.push(pl.to_unsafe_h())
    end
    state_local = params[:state_local]
    cast_uuid = params[:state_local][:cast_uuid]

    if state_local[:shuffle] == "on"
      clicked = playlist.shift # We want the clicked mp3 to play first, all else is shuffled
      playlist.shuffle!
      playlist.unshift(clicked)
    end

    buffering_pause = 3.0  # Magic number here: number of seconds to wait for device to go from buffering to playing. We could use the wait_for_device_status() function, but sadly the device starts playing about 1s before the status updates to PLAYING so this isn't an option.

    device = Device.get_by_uuid(cast_uuid)

    # If you're playing a radio station and try to play it again, don't restart playback to avoid a gap in audio while it's re-buffering
    #if state_local[:mode] == "radio" && device.state_local[:radio_station] == playlist[0]['url']
    #  puts "== Already playing this station!"
    #  render :json => { success: true } and return
    #end

    device.state_local = state_local.to_unsafe_h
    device.playlist = playlist
    $redis.hset("thread_command", cast_uuid, "play")  # See: device.rb#refresh

    sleep(buffering_pause)
    render :json => { success: true }
  end

  def stop
    device = Device.get_by_uuid(params[:cast_uuid])
    device.stop()
    render :json => { success: true }
  end

  def pause
    device = Device.get_by_uuid(params[:cast_uuid])
    device.pause()
    render :json => { success: true }
  end

  def resume
    device = Device.get_by_uuid(params[:cast_uuid])
    device.resume()
    render :json => { success: true }
  end

  def refresh
    mode = params[:mode]

    stats = Sync.refresh(mode)
    render :json => stats
  end

end