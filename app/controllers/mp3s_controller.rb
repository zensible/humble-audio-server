class Mp3sController < ApiController

  skip_before_action :verify_authenticity_token, :only => [:play]

  def index
    mode = params[:mode]
    id = params[:id]

    folders = []
    playlists = []

    if mode == "music"
      mp3s = Mp3.where("mode = 'music' AND folder_id = '#{id}'").order("track_nr, artist, album, title, filename")
    elsif mode == "spoken"
      mp3s = Mp3.where("mode = 'spoken' AND folder_id = '#{id}'").order("filename, title")
    elsif mode == "white-noise"
      mp3s = Mp3.where("mode = 'white-noise'").order("title")
    end

    render :json => mp3s
  end

  def get_by_id
    id = params[:id]
    mp3 = Mp3.find_by_id(id)
    render :json => mp3
  end

  def get_folders
    mode = params[:mode]
    #folder_id = params[:folder_id]
    folders = []
    Folder.all.order("basename").where("mode = '#{mode}'").each do |fol|
      folders.push(fol.to_h)
    end
    render :json => folders
  end

  def get_folder
    mode = params[:mode]
    folder_id = params[:folder_id]

    fol = Folder.find_by_id(folder_id)

    render :json => fol.to_h
  end

  def next
    $redis.hset("thread_command", params[:cast_uuid], "next")
    render :json => { success: true }
  end

  def prev
    Rails.logger.info("== PREVVVV")
    $redis.hset("thread_command", params[:cast_uuid], "prev")
    render :json => { success: true }
  end

  def play
    orig_index = params[:playlist_index]
    playlist_index = params[:playlist_index]
    playlist_params = params[:playlist]
    update_only = params[:update_only]  # When sort changes, we want to update all these vars the same way as playing, but without actually modifying playback
    playlist = []
    playlist_params.each do |pl|
      playlist.push(pl.to_unsafe_h())
    end

    playlist_order = []
    playlist.each_with_index do |pl, i|
      playlist_order.push(i)
    end

    state_local = params[:state_local]
    cast_uuid = params[:state_local][:cast_uuid]

    buffering_pause = 3.0  # Magic number here: number of seconds to wait for device to go from buffering to playing. We could use the wait_for_device_status() function, but sadly the device starts playing about 1s before the status updates to PLAYING so this isn't an option.

    device = Device.get_by_uuid(cast_uuid)

    # If you're playing a radio station and try to play it again, don't restart playback to avoid a gap in audio while it's re-buffering
    #if state_local[:mode] == "radio" && device.state_local[:radio_station] == playlist[0]['url']
    #  puts "== Already playing this station!"
    #  render :json => { success: true } and return
    #end

    device.state_local = state_local.to_unsafe_h
    device.playlist = playlist
    device.playlist_order = playlist_order
    device.playlist_index = playlist_index
    device.orig_index = orig_index

    if state_local[:shuffle] == "on"
      device.shuffle_playlist()
    end

    if update_only.nil?
      $redis.hset("thread_command", cast_uuid, "play")  # See: device.rb#refresh
      sleep(buffering_pause)
    end

    render :json => { success: true }
  end

  def stop
    device = Device.get_by_uuid(params[:cast_uuid])
    device.stop()
    save_bookmark_by_device(device)
    render :json => { success: true }
  end

  def stop_all
    Device.stop_all(true)
    render :json => { success: true }
  end

  def save_bookmark
    mp3_id = params[:mp3_id]
    elapsed = params[:elapsed].to_i

    mp3 = Mp3.find_by_id(mp3_id)
    fold = Folder.find_by_id(mp3.folder_id)

    elapsed_friendly = Time.at(elapsed).utc.strftime("%Hh %Mm %Ss")
    elapsed_friendly = elapsed_friendly.gsub(/^00h /, "")

    fold.bookmark = JSON.dump({
        elapsed: elapsed,
        elapsed_friendly: elapsed_friendly,
        mp3: (mp3 ? mp3.to_h : {})
      }
    )
    fold.save

    render :json => { success: true }
  end

  def save_bookmark_by_device(device)
    Rails.logger.info("====== 001 " + device.inspect)
    if device.state_local && device.state_local[:mp3] && device.state_local[:mode] == "spoken"
    Rails.logger.info("====== 002")
      mp3 = Mp3.find_by_id(device.state_local[:mp3][:id])
      fold = Folder.find_by_id(mp3.folder_id)

      elapsed_friendly = Time.at(device.to_h()[:state_local]["elapsed"]).utc.strftime("%Hh %Mm %Ss")
      elapsed_friendly = elapsed_friendly.gsub(/^00h /, "")

      fold.bookmark = JSON.dump({
          elapsed: device.to_h()[:state_local]["elapsed"].to_i,
          elapsed_friendly: elapsed_friendly,
          mp3: (mp3 ? mp3.to_h : {})
        }
      )
      fold.save
    end
  end

  def pause
    device = Device.get_by_uuid(params[:cast_uuid])
    device.pause()
    save_bookmark_by_device(device)
    render :json => { success: true }
  end

  def resume
    device = Device.get_by_uuid(params[:cast_uuid])
    device.resume()
    render :json => { success: true }
  end

  def seek
    device = Device.get_by_uuid(params[:cast_uuid])
    device.seek((params[:secs] || 0).to_i)
    render :json => { success: true }
  end

  def refresh
    mode = params[:mode]

    stats = Sync.refresh(mode, "http://" + request.host_with_port)
    render :json => stats
  end

end