class Device
  require 'benchmark'

  attr_accessor :sides
  @uuid = ""

  def initialize(uuid)
    @uuid = uuid
  end

  def cast_var()
    "casts_by_uuid['#{@uuid}']"
  end

  def select()
    str = %Q{
      #{cast_var}.wait()
    }
    PyChromecast.run(str)
    $redis.set("cur_cast", @uuid)
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

$init_casts_by_uuid = "
casts_by_uuid = {}
print('Number of casts:')
print(len(chromecasts))
"
    PyChromecast.run($init_casts_by_uuid)

$populate_casts_var = "for cc in chromecasts:
  casts_by_uuid[cc.uuid.urn[9:]] = cc

"
    PyChromecast.run($populate_casts_var, false, false)


    PyChromecast.run("print(casts_by_uuid)")

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
    devices
  end

  def cast_status
    str = %Q{
      print(#{cast_var}.status.status_text)
    }
    PyChromecast.run(str)
  end

  def player_status
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

  def stop()
    str = %Q{
      #{cast_var}.media_controller.stop()
    }
    PyChromecast.run(str)
  end

  def pause()
    str = %Q{
      #{cast_var}.media_controller.pause()
    }
    PyChromecast.run(str)
  end

  def resume()
    str = %Q{
      #{cast_var}.media_controller.play()
    }
    PyChromecast.run(str)
  end

  def set_volume(level)
    str = %Q{
      #{cast_var}.set_volume(#{level})
    }
    PyChromecast.run(str)

    devices = JSON.load($redis.get("devices"))

    groups = devices["groups"]
    groups.each do |grp|
      if grp["uuid"] == @uuid
        grp["volume_level"] = level
      end
    end
    audios = devices["audios"]
    audios.each do |aud|
      if aud["uuid"] == @uuid
        aud["volume_level"] = level
      end
    end

    data = {
      audios: audios,
      groups: groups
    }
    $redis.set("devices", JSON.dump(data))
    ActionCable.server.broadcast "device", $redis.get("devices")
  end

end