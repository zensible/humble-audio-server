class CreateMp3s < ActiveRecord::Migration[5.0]
  def change
    create_table :mp3s do |t|
      t.string :mode
      t.integer :rank
      t.string :title
      t.string :album
      t.string :artist
      t.integer :year
      t.string :genre
      t.integer :track_nr
      t.integer :length_seconds
      t.integer :folder_id
      t.string :path, :limit => 1024
      t.string :url, :limit => 1024
      t.string :filename
      t.string :md5
    end
  end
end
