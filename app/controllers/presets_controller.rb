class PresetsController < ApplicationController
  require 'rest-client'

  skip_before_action :verify_authenticity_token, :only => [:create, :update]

  def index
    render :json => Preset.all.order(:name)
  end

  def create
    arr = []
    $devices.each do |dev|
      if dev.player_status == 'PLAYING'
        parameters = {
          playlist: dev.playlist,
          state_local: dev.state_local
        }
        arr.push(parameters)
      end
    end
    Preset.create(:name => params[:name], :preset => JSON.dump(arr))

    render :json => { success: true }
  end

  def play
    @time_started = Time.now.to_i.to_s

    # First, stop everything currently playing
    Device.stop_all(true)
    sleep 1

    preset = Preset.find(params[:id])
    initheader = { 'Content-Type' => 'application/json;charset=UTF-8' }

    play = JSON.load(preset.preset)
    play.each_with_index do |pl, cast_num|

      fn = Rails.root.join("tmp/#{preset.id}.#{cast_num}.preset")
      File.write(fn, JSON.dump(pl))
      cmd = "curl -v -X POST -H \"Content-Type: application/json;charset=UTF-8\" --data-binary \"@#{fn}\" #{$http_address}/api/mp3s/play > out.txt"

      spawn(cmd)
    end


    render :json => { success: true }

#    abort cmd
  end

  def update
    preset = Preset.find_by_id(params[:id])
    preset.update_attributes({
      :schedule_days => params[:schedule_days],
      :schedule_start => params[:schedule_start],
      :schedule_end => params[:schedule_end]
    })

    render :json => { success: true }
  end

  def destroy
    abort params.inspect
  end
end