# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170218161338) do

  create_table "crono_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "job_id",                               null: false
    t.text     "log",               limit: 4294967295
    t.datetime "last_performed_at"
    t.boolean  "healthy"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.index ["job_id"], name: "index_crono_jobs_on_job_id", unique: true, using: :btree
  end

  create_table "folders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "parent_folder_id"
    t.string  "full_path"
    t.string  "mode"
    t.string  "basename"
    t.string  "bookmark"
  end

  create_table "mp3s", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "mode"
    t.integer "rank"
    t.string  "title"
    t.string  "album"
    t.string  "artist"
    t.integer "year"
    t.string  "genre"
    t.integer "track_nr"
    t.integer "length_seconds"
    t.integer "folder_id"
    t.string  "path",           limit: 1024
    t.string  "url",            limit: 1024
    t.string  "filename"
    t.string  "md5"
  end

  create_table "playlists", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string  "name"
    t.integer "rank"
    t.text    "mp3s", limit: 65535
  end

  create_table "presets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.text   "preset",         limit: 65535
    t.string "options"
    t.string "schedule_days"
    t.string "schedule_start"
    t.string "schedule_end"
  end

end
