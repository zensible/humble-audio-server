class Preset < ApplicationRecord

  def play(http_address)
    initheader = { 'Content-Type' => 'application/json;charset=UTF-8' }

    play = JSON.load(self.preset)
    play.each_with_index do |pl, cast_num|

      fn = Rails.root.join("tmp/#{self.id}.#{cast_num}.preset")
      File.write(fn, JSON.dump(pl))
      cmd = "curl -v -X POST -H \"Content-Type: application/json;charset=UTF-8\" --data-binary \"@#{fn}\" #{http_address}/api/mp3s/play > out.txt"
      puts "====\n#{cmd}\n==="
      spawn(cmd)
    end
  end

  def get_crono
    str = ""
    if !self.schedule_start.blank?
      jobname = "PresetJob#{self.id}"
      arr = self.schedule_start.split(" ")
      (hour, min) = arr[0].split(":")
      ampm = arr[1].upcase()
      if ampm == "PM"
        hour = hour.to_i + 12
      end

      str += %Q{
        class #{jobname}Start
          def perform
            preset = Preset.find(#{self.id})
            preset.play("#{$http_address}")
          end
        end
      }

      str += %Q{
        class #{jobname}Stop
          def perform
            spawn("curl -v #{$http_address}/api/mp3s/stop_all > out.txt")
          end
        end
      }

      daysStart = self.schedule_days
      if self.schedule_days.blank?
        daysStart = "SU M TU W TH F SA"
      end
      arr = daysStart.split(/\s+/)
      arr.each do |day|
        puts "day: #{day}"
        day_pretty = ""
        case day
        when "SU"
          day_pretty = ":sunday"
        when "M"
          day_pretty = ":monday"
        when "TU"
          day_pretty = ":tuesday"
        when "W"
          day_pretty = ":wednesday"
        when "TH"
          day_pretty = ":thursday"
        when "F"
          day_pretty = ":friday"
        when "SA"
          day_pretty = ":saturday"
        else
          raise "Invalid day"
        end
        str += "Crono.perform(#{jobname}Start).every 1.week, on: #{day_pretty}, at: {hour: #{hour}, min: #{min}}\n"
        if !self.schedule_end.blank?
          arr = self.schedule_end.split(" ")
          (hour2, min2) = arr[0].split(":")
          ampm = arr[1].upcase()
          if ampm == "PM"
            hour2 = hour2.to_i + 12
          end
          str += "Crono.perform(#{jobname}Stop).every 1.week, on: #{day_pretty}, at: {hour: #{hour2}, min: #{min2}}\n"
        end
      end
    end
    return str
  end

end
