class CreatePlaylists < ActiveRecord::Migration[5.0]
  def change
    create_table :playlists do |t|
      t.string :name
      t.integer :rank
      t.text :mp3s
    end
  end
end
