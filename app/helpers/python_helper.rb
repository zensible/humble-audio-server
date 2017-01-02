module PythonHelper

  def parse_result(cmd, str)
    #puts "BEFORE: [[#{str}]] cmd: [[#{cmd}]]"
    # Trim off trailing >>> and preceding command so we return only output
    str = str.gsub(/\r*\n>>>/, "")
    str = str.gsub(/\s?#{Regexp.escape(cmd)}/, "")

    #puts "AFTER: [[#{str}]]"
    return str
  end

  def run_py(str)
    retval = nil
    str.split(/\n/).each do |cmd|
      next if cmd.blank? || cmd.gsub(/\s+/, "").blank?
      cmd = cmd.gsub(/^\s+/, '')
      puts "= RUN: [#{cmd}]"
      STDOUT.flush
      $pyin.puts cmd
      #sleep(0.01)
      $pyout.expect(">>>") do |result|
        retval = parse_result(cmd, result[0])
        puts "= result1: ***#{retval}***"
        STDOUT.flush
      end
    end
    return retval
  end

#[DeviceStatus(friendly_name=u'Bedroom-Bruce', model_name=u'Chromecast Audio', manufacturer=u'Google Inc.', api_version=(1, 0), uuid=UUID('a8a9ee5a-26df-595c-c566-c46b19006f7f'), cast_type='audio'), DeviceStatus(friendly_name=u'Bedroom-Justin', model_name=u'Chromecast Audio', manufacturer=u'Google Inc.', api_version=(1, 0), uuid=UUID('1bb851ea-5b0a-fce7-f395-16e1e13a86b9'), cast_type='audio'), DeviceStatus(friendly_name=u'DiningRoom', model_name=u'Chromecast', manufacturer=u'Google Inc.', api_version=(1, 0), uuid=UUID('4e497a5d-2693-236f-dab4-d03b8176e34f'), cast_type='cast')]

  def refresh_devices()
    $get_devices = "
chromecasts = pychromecast.get_chromecasts()
arr = [ { u'friendly_name': cc.device.friendly_name, u'model_name': cc.device.model_name, 'uuid': cc.device.uuid.urn[9:], 'cast_type': cc.device.cast_type } for cc in chromecasts]
print(json.dumps(arr))
    "
    all = run_py($get_devices)
    all = JSON.parse(all)
    devices = {
      left: [],
      right: []
    }
    found = false
    # Filter out non-audio chromecasts if any
    all.each do |dev|
      if dev['cast_type'] == 'audio' || dev['cast_type'] == 'group'
        found = true
        if dev['friendly_name'].match(/^L/)
          devices[:left].push(dev)
        else
          devices[:right].push(dev)
        end
      end
    end
    if !found
      raise "No chromecast audio devices found on the network!"
    end
    $redis.set("devices", JSON.dump(devices))
  end

  def select_cast(nam)
    str = %Q{
      cast = next(cc for cc in chromecasts if cc.device.friendly_name == "#{nam}")
      cast.wait()
    }
    run_py(str)
    $redis.set("cur_cast", nam)
  end

  def play_url(url)
    str = %Q{
      mc = cast.media_controller
      mc.play_media('#{url}', 'audio/mp3')
    }
    run_py(str)
  end

  def cast_stop()
    str = %Q{
      mc = cast.media_controller
      mc.stop()
    }
    run_py(str)
  end

  def cast_pause()
    str = %Q{
      mc = cast.media_controller
      mc.pause()
    }
    run_py(str)
  end

end