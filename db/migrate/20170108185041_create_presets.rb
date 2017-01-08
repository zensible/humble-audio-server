class CreatePresets < ActiveRecord::Migration[5.0]
  def change
    create_table :presets do |t|
      t.string :name
      t.text :preset
      t.string :options
      t.string :schedule_days
      t.time :schedule_start
      t.time :schedule_end
    end
  end
end
