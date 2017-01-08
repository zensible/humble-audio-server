class PresetsController < ApplicationController
  require 'rest-client'

  skip_before_action :verify_authenticity_token, :only => [:create]

  def index
    render :json => Preset.all.order(:name)
  end

  def create
    shared = JSON.load($redis.get("state_shared") || "[]") || []
    arr = []
    shared.each_with_index do |sh|
      cast_uuid = sh["cast_uuid"]
      playlist = JSON.load($redis.hget("cur_playlist", cast_uuid))
      parameters = {
        playlist: playlist,
        state_local: sh
      }
      arr.push(parameters)
    end
    Preset.create(:name => params[:name], :preset => JSON.dump(arr))

    render :json => { success: true }
  end

  def play
    # First, stop everything currently playing
    shared = JSON.load($redis.get("state_shared") || "[]") || []
    shared.each do |sh|
      cast_uuid = sh["cast_uuid"]
      $redis.hset("device_play_started", cast_uuid, "-1")
    end
    sleep 1

    preset = Preset.find(params[:id])
    initheader = { 'Content-Type' => 'application/json;charset=UTF-8' }

    play = JSON.load(preset.preset)
    play.each_with_index do |pl, cast_num|

      fn = Rails.root.join("tmp/#{cast_num}.preset")
      File.write(fn, JSON.dump(pl))
      cmd = "curl -v -X POST -H \"Content-Type: application/json;charset=UTF-8\" --data-binary \"@#{fn}\" #{$http_address}/api/mp3s/play > out.txt"

      spawn(cmd)
    end


    render :json => { success: true }

#    abort cmd
  end

  def destroy
    abort params.inspect
  end
end