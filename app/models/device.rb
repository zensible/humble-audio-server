class Device

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
    $get_devices = "
chromecasts = pychromecast.get_chromecasts()
arr = [ { u'friendly_name': cc.device.friendly_name, u'model_name': cc.device.model_name, 'uuid': cc.device.uuid.urn[9:], 'cast_type': cc.device.cast_type } for cc in chromecasts]
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
    if !found
      raise "No chromecast audio devices found on the network! Please set up your chromecasts and try again."
    end
    $redis.set("devices", JSON.dump(devices))
  end

  def self.play_url(url)
    str = %Q{
      mc = cast.media_controller
      mc.play_media('#{url}', 'audio/mp3')
    }
    PyChromecast.run(str)
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

end