class Device
  require 'benchmark'

  attr_accessor :uuid, :cast_type, :friendly_name, :volume_level, :status_text, :model_name
  attr_accessor :state_local, :playlist, :playlist_index, :playlist_order, :orig_index
  attr_accessor :is_orig_play2

  MAX_BUFFERING_WAIT ||= 10
  MAX_PLAYING_WAIT ||= 10
  RETRY_WAIT ||= 5
  MAX_RETRIES ||= 3

  @uuid = ""
  @cast_type = ""
  @friendly_name = ""
  @volume_level = ""
  @status_text = ""
  @model_name = ""
  @state_local = ""
  @playlist = []
  @playlist_index = 0
  @playlist_order = []

  @is_orig_play2 = false

  def initialize(hsh)
    @uuid = hsh["uuid"]
    @cast_type = hsh["cast_type"]
    @friendly_name = hsh["friendly_name"]
    @volume_level = hsh["volume_level"]
    @status_text = hsh["status_text"]
    @model_name = hsh["model_name"]
    @state_local = hsh["state_local"] || {}
    @playlist = hsh["playlist"] || []
    @playlist_index = 0
  end

  def cast_var()
    "casts_by_uuid['#{@uuid}']"
  end

  def children
    return JSON.load($redis.hget("group_children", @uuid) || "[]") || "[]"
  end

  def select()
    str = %Q{
      #{cast_var}.wait()
    }
    PyChromecast.run(str)
  end

  # Get all devices from cache
  #def self.get_all()
  #  str = $redis.get("devices") 
  #  if str.blank? # Redis got cleared or some such, repopulate devices
  #    self.refresh()
  #    str = $redis.get("devices")
  #  end
  #  # {"uuid"=>"ebdea152-4479-41c8-af85-5b3b0231c9e2", "cast_type"=>"group", "friendly_name"=>"ALL", "volume_level"=>0.8125, "status_text"=>"", "model_name"=>"Google Cast Group"}
  #  return JSON.load(devices)
  #end

  # Refresh list of devices and save to cache
  def self.refresh()

    # Without this sleep, the cc.status calls will fail with: "AttributeError: 'NoneType' object has no attribute 'status_text'"
    # I'm making it configurable here in case others require a longer sleep
    sleep_before_status = 1 

    if Rails.env.test? || ENV['DEBUG'] == 'true'
      puts "== Skipping get chromecasts call -- test mode or DEBUG=true"
      all = '[{"uuid": "72af5e77-b9c9-150a-9372-f613c16698b8", "cast_type": "audio", "friendly_name": "Test-CCA", "volume_level": 0.4000000059604645, "status_text": "Ready To Cast", "model_name": "Chromecast Audio"}]'
    else  # For test mode, don't hit a real chromecast, these calls are very slow
      $get_devices = "
chromecasts = pychromecast.get_chromecasts()
time.sleep(#{sleep_before_status})
arr = [ { u'friendly_name': cc.device.friendly_name, u'model_name': cc.device.model_name, 'uuid': cc.device.uuid.urn[9:], 'cast_type': cc.device.cast_type, 'status_text': cc.status.status_text, 'volume_level': cc.status.volume_level } for cc in chromecasts]
print(json.dumps(arr))
"
      all = PyChromecast.run($get_devices)

      $init_casts_by_uuid = "
casts_by_uuid = {}
print('Number of casts:')
print(len(chromecasts))
"
      PyChromecast.run($init_casts_by_uuid)

    $populate_casts_var = "for cc in chromecasts:
  cc.wait()
  casts_by_uuid[cc.uuid.urn[9:]] = cc

"
      PyChromecast.run($populate_casts_var, false, false)
      sleep 1
      PyChromecast.run("print(casts_by_uuid)")
    end

    puts "== all #{all.inspect}"
    devs = JSON.parse(all || "[]")
    if devs.length == 0
      puts "==== WARNING: No chromecast audio devices found on the network! Server will only be able to stream to web browsers."
    else
      $has_chromecasts = true
    end
    #$redis.set("devices", JSON.dump(devs))

    $devices = []
    devs.each do |hsh|
      $devices.push(Device.new(hsh)) if hsh["cast_type"] == "group" || hsh["cast_type"] == "audio"
    end

    stop_all() # Since the threads which monitored the casts will have died if we're here, we have no idea what they're playing. Stop all casts from playing for sanity's sake.

    buffering_pause = 3

    Thread.abort_on_exception = true if Rails.env.test?

    $threads.keys.each do |key|
      Thread.kill($threads[key])
    end
#puts $devices.inspect

    $devices.each do |device|
      @test_idle_wait = 0.0

      next if device.nil?
      #puts device.inspect
      uuid = device.uuid
      $threads[uuid] = Thread.new do
        begin
          while(true) do
            cmd = ""

            $semaphore.synchronize {
              cmd = $redis.hget("thread_command", uuid)
              #puts "+++---+++ uuid: #{uuid}, cmd: #{cmd}" if ENV['DEBUG'] == 'true'
            }

            case cmd
            when "play" # See: mp3s_controller.rb#play
              @test_idle_wait = 0.0 if Rails.env.test?

              # User clicked play
              if device.cast_type == "group"
                device.children.each do |child_uuid|
                  puts "====+++++ CHILD #{child_uuid}" if ENV['DEBUG'] == 'true'
                  child = Device.get_by_uuid(child_uuid)
                  child.stop() if child
                end
                Device.broadcast()
              end

              #device.playlist_index = 0
              device.play_at_index(0, true)
            when "wait_for_idle"
              if Rails.env.test?
                sleep 1
                @test_idle_wait += 1
                if @test_idle_wait < 5
                  #puts "____ TEST WAIT"
                  next
                end
                #puts "____ TEST NEXT"
                @test_idle_wait = 0
              end
              # When the cast goes from BUFFERING/PLAYING to IDLE, that means the song has ended or couldn't be played. Move on to the next item in the playlist
              if device.player_status("IDLE") == "IDLE"
                continue_playing = true
                device.playlist_index += 1
                if device.state_local[:repeat] == "one"
                  device.playlist_index -= 1
                else
                  if device.playlist_index >= device.playlist_order.length # Reached the end of the playlist
                    #puts @is_orig_play2.inspect
                    #puts device.playlist_order[device.playlist_index].to_s
                    #puts device.orig_index.to_s
                    #puts device.state_local[:repeat].to_s

                    if !@is_orig_play2 && (!device.playlist_order[device.playlist_index] || device.playlist_order[device.playlist_index] == device.orig_index)
                      if device.state_local[:repeat] == 'all'
                        device.playlist_index = 0
                      else
                        continue_playing = false
                        Device.broadcast() # Inform user playlist is done playing
                      end
                    end
                  end
                end
                #puts "=== PLAY NEXT: #{device.playlist_index}"
                device.play_at_index(0, false) if continue_playing
              end
            when "next"
              @test_idle_wait = 0.0 if Rails.env.test?
              #puts "=== NEEXXTT"
              device.playlist_index += 1
              device.playlist_index = 0 if device.playlist_index >= device.playlist.length
              device.play_at_index(0, false)
            when "prev"
              @test_idle_wait = 0.0 if Rails.env.test?
              #puts "=== PERV"
              device.playlist_index -= 1
              device.playlist_index = device.playlist.length - 1 if device.playlist_index < 0
              device.play_at_index(0, false)
            end
            sleep 1
          end
        rescue Exception => ex
          puts %Q{================EXCEPTION==============

#{ex.inspect}
#{ex.backtrace.join("\n")}

================/EXCEPTION==============}
        end
      end

    end
    return $devices
  end

  def play_at_index(retry_num, is_orig_play)
    @is_orig_play2 = is_orig_play
    puts "Playlist index: #{@playlist_index}" if ENV['DEBUG'] == 'true'

    mp3 = @playlist[@playlist_order[@playlist_index]]
#puts "Play at index: #{@playlist_index} : "
#puts mp3.inspect

    if mp3[:id] == -1
      mp3_obj = {
        mode: '',
        title: '',
        filename: '',
        length_seconds: 0,
        artist: '',
        album: ''
      }
    else
      mp3_obj = Mp3.find_by_id(mp3[:id]).to_h
    end
    @state_local[:mp3] = mp3_obj
    #@state_local[:mp3_id] = mp3[:id]
    #@state_local[:mp3_url] = mp3[:url]

#puts "002.2"
    skip_to_seconds = 0
    if @state_local["seek"] # We only want to seek the first track in the playlist
      skip_to_seconds = @state_local["seek"]
      @state_local["seek"] = 0
    end

    play_url(mp3[:url])
    #puts mp3[:url]
    sleep(0.5)

    if wait_for_device_status('BUFFERING', 0.5, MAX_BUFFERING_WAIT) # Wait 10 seconds to go from IDLE/UNKNOWN -> BUFFERING
      Device.broadcast()

      if skip_to_seconds && skip_to_seconds > 0
        seek(skip_to_seconds)
        $redis.hset("thread_command", @uuid, "wait_for_idle") # Wait indefinitely for "IDLE" status a.k.a. MP3 has stopped playing
      else
        if wait_for_device_status('PLAYING', 0.5, MAX_PLAYING_WAIT) # Wait 5 seconds to go from BUFFERING -> PLAYING
          @state_local[:elapsed] = 0
          @state_local[:start] = Time.now().to_i - skip_to_seconds
          @state_local[:paused_start] = 0
          @state_local[:paused_time] = 0

          Device.broadcast()
          $redis.hset("thread_command", @uuid, "wait_for_idle") # Wait indefinitely for "IDLE" status a.k.a. MP3 has stopped playing

          return true
        else
          # Could not get MP3
          Rails.logger.warn("= 102 = Could not retrieve buffer for mp3 within #{MAX_PLAYING_WAIT}. Waiting #{RETRY_WAIT} seconds and retrying. Retry ##{retry_num + 1} of #{MAX_RETRIES} for #{mp3[:url]}")
          sleep(RETRY_WAIT)  # Wait 5 seconds and try again
          if retry_num < MAX_RETRIES
            return play_at_index(retry_num + 1, is_orig_play)
          else
            Rails.logger.error("= 101 = Tried #{MAX_RETRIES} times and couldn't go from BUFFERING to PLAYING - give up and cancel play")
            $redis.hset("thread_command", @uuid, "")
            return false
          end
        end
      end
    else
      puts "Check: " + mp3[:url]
      sleep 60
      Rails.logger.error("= 103 = Couldn't download/buffer mp3 in #{MAX_BUFFERING_WAIT} seconds. Canceling play.")
      $redis.hset("thread_command", @uuid, "")
      return false
    end
  end

  $test_status_override = ""
  def wait_for_device_status(str, interval = 0.5, max_wait = 5)
    if Rails.env.test?
      $test_status_override = str
      case str
      when "BUFFERING"
        sleep 1
        return true
      when "PLAYING"
        sleep 1
        return true
      else
        return true
      end
    end

    player_state = ""
    reps = 0
    while (player_state != str && reps * interval < max_wait)
      reps += 1
      puts "Waiting for...#{str}. \tCaller: " + caller[0] if ENV['DEBUG'] == 'true'
      player_state = player_status()
      sleep(interval) # Poll device every half second
    end
    if reps * interval >= max_wait # Timed out waiting for status
      return false
    end
    return true
  end

  def self.get_by_uuid(uuid)
    $devices.each do |dev|
      return dev if dev.uuid == uuid
    end
    nil
  end

  def self.stop_all(broadc = false)
    puts "\n\n\n======= STOP ALL =====\n\n\n"
    $devices.each do |dev|
      dev.stop()
      $redis.hset("thread_command", dev.uuid, "")
    end

    all_stopped = false
    reps = 0
    max_reps = 0.5 * 2 * 30 # Wait a max of 30 seconds for all devices to stop playing
    while !all_stopped
      all_stopped = true
      $devices.each do |dev|
        stat = dev.player_status
        all_stopped = false if stat == "PLAYING"
      end
      sleep 0.5
      reps += 1
      if reps >= max_reps
        raise "Could not stop all devices!"
      end
    end

    Device.broadcast() if broadc
  end

  def cast_status
    str = %Q{
      print(#{cast_var}.status.status_text)
    }
    PyChromecast.run(str)
  end

  def player_status(test_default = nil)
    if Rails.env.test?
      $test_status_override = test_default if test_default
      return $test_status_override
    end
    #  cast = next(cc for cc in chromecasts if cc.device.uuid.urn == "urn:uuid:#{uuid}")
    #  cast.wait()
    str = %Q{
      print(#{cast_var}.media_controller.status.player_state)
    }
    PyChromecast.run(str)
  end

  def play_url(url)
    str = %Q{
      #{cast_var}.media_controller.play_media('#{url}', 'audio/mp3')
    }
    PyChromecast.run(str)
  end

  def play()

  end

  def stop()
    str = %Q{
      #{cast_var}.media_controller.stop()
    }
    PyChromecast.run(str)

    # This clears what's playing on front-end
    @state_local['mode'] = ""
    @state_local['folder_id'] = nil
    #@state_local['mp3_url'] = ""
    #@state_local['mp3_id'] = nil
    @state_local['mp3'] = {}
    @state_local['radio_station'] = nil
    @state_local['shuffle'] = 'off'
    @state_local['repeat'] = 'off'
  end

  def pause()
    @test_idle_wait = 0
    str = %Q{
      #{cast_var}.media_controller.pause()
    }
    PyChromecast.run(str)
    wait_for_device_status("PAUSED", 0.1)

    @state_local[:paused_start] = Time.now().to_f

    Device.broadcast()
  end

  def resume()
    str = %Q{
      #{cast_var}.media_controller.play()
    }
    PyChromecast.run(str)
    wait_for_device_status("PLAYING", 0.1)

    @state_local[:paused_time] += Time.now().to_f - (@state_local[:paused_start] || 0)

    Device.broadcast()
  end

  def seek(secs)
    str = %Q{
      #{cast_var}.media_controller.seek(#{secs})
    }
    PyChromecast.run(str)

    @state_local[:elapsed] = 0
    @state_local[:start] = Time.now().to_i - secs
    @state_local[:paused_start] = 0
    @state_local[:paused_time] = 0

    if wait_for_device_status('BUFFERING', 0.5, MAX_PLAYING_WAIT)
      if wait_for_device_status('PLAYING', 0.5, MAX_PLAYING_WAIT)
        Device.broadcast()
      else
        Rails.logger.info "-- Could not seek!"
      end
    end
  end

  def set_volume(level)
    if @uuid == 'local'

    else
      str = %Q{
        #{cast_var}.set_volume(#{level})
      }
      PyChromecast.run(str)
    end

    @volume_level = level.to_f

    Device.broadcast()
  end

  def set_shuffle(shuffle)
    @state_local[:shuffle] = shuffle
    if shuffle == 'on'
      self.shuffle_playlist()
    else
      self.unshuffle_playlist()
    end
    Device.broadcast()
  end

  def set_repeat(repeat)
    @state_local[:repeat] = repeat

    Device.broadcast()
  end

  def shuffle_playlist
    return unless @playlist_order && !@playlist_index.nil?
    cur_index_val = @playlist_order[@playlist_index]
    #playlist_order = _.reject(playlist_order, function(num){ return num == cur_index_val; });
    @playlist_order.delete(cur_index_val)

    @playlist_order.shuffle!
    @playlist_order.unshift(cur_index_val)
    @playlist_index = 0;
  end

  def unshuffle_playlist
    return unless @playlist_order && !@playlist_index.nil?
    cur_index_val = @playlist_order[@playlist_index]

    @playlist_order = @playlist_order.sort()
    @playlist_index = @playlist_order.find_index(cur_index_val)
  end

  def to_h
    if @state_local[:start]
      @state_local[:elapsed] = Time.now().to_f - @state_local[:start] - @state_local[:paused_time]
    end
    {
      uuid: @uuid,
      cast_type: @cast_type,
      friendly_name: @friendly_name,
      volume_level: @volume_level,
      status_text: @status_text,
      model_name: @model_name,
      state_local: @state_local,
      player_status: player_status(),
      playbar: @play_status,
      children: children()
    }
  end

  def self.broadcast()
    arr = []
    num_casting = -1
    $devices.each do |dev|
      hsh = dev.to_h()
      puts "BROADCAST STATUS: #{hsh[:player_status]}"
      if hsh[:player_status] == 'BUFFERING' || hsh[:player_status] == 'PLAYING'
        num_casting += 1
        hsh[:num_casting] = num_casting
      end
      arr.push(hsh)
    end
    ActionCable.server.broadcast (Rails.env.test? ? "device_test" : "device"), JSON.dump(arr)
  end

end