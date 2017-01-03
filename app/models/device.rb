class Device
  require 'benchmark'

  def self.select(friendly_name)
    str = %Q{
      cast = next(cc for cc in chromecasts if cc.device.friendly_name == "#{friendly_name}")
      cast.wait()
    }
    PyChromecast.run(str)
    $redis.set("cur_cast", friendly_name)
  end

  # Get all devices from cache
  def self.get_all()
    devices = $redis.get("devices")
    if devices.blank? # Redis got cleared or some such, repopulate devices
      self.refresh()
      devices = $redis.get("devices")
    end
    return devices
  end

  # Refresh list of devices and save to cache
  def self.refresh()

    # Without this sleep, the cc.status calls will fail with: "AttributeError: 'NoneType' object has no attribute 'status_text'"
    # I'm making it configurable here in case others require a longer sleep
    sleep_before_status = 1 

    $get_devices = "
chromecasts = pychromecast.get_chromecasts()
time.sleep(#{sleep_before_status})
arr = [ { u'friendly_name': cc.device.friendly_name, u'model_name': cc.device.model_name, 'uuid': cc.device.uuid.urn[9:], 'cast_type': cc.device.cast_type, 'status_text': cc.status.status_text, 'volume_level': cc.status.volume_level } for cc in chromecasts]
print(json.dumps(arr))
    "
    all = PyChromecast.run($get_devices)
    all = JSON.parse(all)
    devices = {
      groups: [],
      audios: []
    }
    found = false
    # Filter out non-audio chromecasts if any
    all.each do |dev|
      if dev['cast_type'] == 'audio'
        found = true
        devices[:audios].push(dev)
      end
      if dev['cast_type'] == 'group'
        found = true
        devices[:groups].push(dev)
      end
    end
    devices[:groups] = devices[:groups].sort_by { |hsh| hsh["friendly_name"] }
    devices[:audios] = devices[:audios].sort_by { |hsh| hsh["friendly_name"] }
    if !found
      raise "No chromecast audio devices found on the network! Please set up your chromecasts and try again."
    end
    $redis.set("devices", JSON.dump(devices))
  end

  def self.player_status
    str = %Q{
      print(mc.status.player_state)
    }
    PyChromecast.run(str)
  end

  def self.play_url(url)
    str = %Q{
      mc = cast.media_controller
      mc.play_media('#{url}', 'audio/mp3')
    }
    PyChromecast.run(str)

    #str = %Q{
    #  print(mc.status.player_state)
    #}

    # Magic number here. Should wait for device state PLAYING, however the change from status BUFFERING to PLAYING seems to be about 1 second longer than when the playback actually begins on the device

    #sleep 3
    #puts Benchmark.measure {
    #  player_state = ""
    #  cnt = 0
    #  while(player_state != "BUFFERING" && cnt < 20)
    #    puts "1 #{player_state}"
    #    player_state = PyChromecast.run(str)
    #    puts "1.1 #{player_state}"
    #    sleep(0.25)
    #  end

    #  cnt = 0
    #  while(player_state == "BUFFERING" && cnt < 20)
    #    puts "2 #{player_state}"
    #    player_state = PyChromecast.run(str)
    #    sleep(0.1)
    #  end
    #}
  end

  def self.stop()
    str = %Q{
      mc = cast.media_controller
      mc.stop()
    }
    PyChromecast.run(str)
  end

  def self.pause()
    str = %Q{
      mc = cast.media_controller
      mc.pause()
    }
    PyChromecast.run(str)
  end

  def self.resume()
    str = %Q{
      mc = cast.media_controller
      mc.play()
    }
    PyChromecast.run(str)
  end

  def self.set_volume(level)
    str = %Q{
      cast.set_volume(#{level})
    }
    PyChromecast.run(str)
  end

end