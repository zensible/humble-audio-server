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
    Preset.update_crono()

    render :json => { success: true }
  end

  def play
    @time_started = Time.now.to_i.to_s

    # First, stop everything currently playing
    Device.stop_all(true)
    sleep 1

    preset = Preset.find(params[:id])
    preset.play($http_address_local)


    render :json => { success: true }
  end

  def update
    preset = Preset.find_by_id(params[:id])
    preset.update_attributes({
      :schedule_days => params[:schedule_days],
      :schedule_start => params[:schedule_start],
      :schedule_end => params[:schedule_end]
    })
    Preset.update_crono()

    render :json => { success: true }
  end

  def destroy
    abort params.inspect
  end
end