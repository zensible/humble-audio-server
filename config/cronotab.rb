
        class PresetJob6Start
          def perform
            preset = Preset.find(6)
            preset.play("http://192.168.0.103:4040")
          end
        end
      
        class PresetJob6Stop
          def perform
            spawn("curl -v http://192.168.0.103:4040/api/mp3s/stop_all > out.txt")
          end
        end
      Crono.perform(PresetJob6Start).every 1.week, on: :sunday, at: {hour: 22, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :monday, at: {hour: 22, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :tuesday, at: {hour: 22, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :wednesday, at: {hour: 22, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :thursday, at: {hour: 22, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :friday, at: {hour: 22, min: 00}
Crono.perform(PresetJob6Start).every 1.week, on: :saturday, at: {hour: 22, min: 00}

        class PresetJob8Start
          def perform
            preset = Preset.find(8)
            preset.play("http://192.168.0.103:4040")
          end
        end
      
        class PresetJob8Stop
          def perform
            spawn("curl -v http://192.168.0.103:4040/api/mp3s/stop_all > out.txt")
          end
        end
      Crono.perform(PresetJob8Start).every 1.week, on: :monday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :tuesday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :wednesday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :thursday, at: {hour: 10, min: 30}
Crono.perform(PresetJob8Start).every 1.week, on: :friday, at: {hour: 10, min: 30}
