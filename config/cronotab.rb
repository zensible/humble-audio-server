
        class UpdateDDNSIP
          def perform
            puts "Updating DDNS IP"
            spawn("curl -s https://www.duckdns.org/update?domains=againstinequality&token=1dff4df8-7f4e-470c-85d5-f908b83f612c&ip=")
          end
        end
        Crono.perform(UpdateDDNSIP).every 30.minutes
      
        class PresetJob6Start
          def perform
            preset = Preset.find(6)
            preset.play("http://192.168.0.103:4040")
          end
        end
      
        class PresetJob6Stop
          def perform
            spawn("curl -u admin:admin -s http://192.168.0.103:4040/api/mp3s/stop_all > out.txt")
          end
        end
      Crono.perform(PresetJob6Start).every 1.week, on: :sunday, at: {hour: 23, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :monday, at: {hour: 23, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :tuesday, at: {hour: 23, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :wednesday, at: {hour: 23, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :thursday, at: {hour: 23, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :friday, at: {hour: 23, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :saturday, at: {hour: 23, min: 00}

        class PresetJob8Start
          def perform
            preset = Preset.find(8)
            preset.play("http://192.168.0.103:4040")
          end
        end
      
        class PresetJob8Stop
          def perform
            spawn("curl -u admin:admin -s http://192.168.0.103:4040/api/mp3s/stop_all > out.txt")
          end
        end
      Crono.perform(PresetJob8Start).every 1.week, on: :monday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :tuesday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :wednesday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :thursday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :friday, at: {hour: 10, min: 30}
