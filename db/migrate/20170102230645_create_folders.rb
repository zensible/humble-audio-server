class CreateFolders < ActiveRecord::Migration[5.0]
  def change
    create_table :folders do |t|
      t.integer :parent_folder_id
      t.string :full_path
      t.string :mode
      t.string :basename
      t.string :bookmark
    end
  end
end
