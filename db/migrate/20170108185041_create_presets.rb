class CreatePresets < ActiveRecord::Migration[5.0]
  def change
    create_table :presets do |t|
      t.string :name
      t.text :preset
      t.string :options
      t.string :schedule_days
      t.string :schedule_start
      t.string :schedule_end
    end
  end
end
