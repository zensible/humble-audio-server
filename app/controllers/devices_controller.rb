class DevicesController < ApiController

  def refresh
    # Wait until terminal is ready

    Device.refresh()
    render :json => @devices
  end

  def get_all
    render :json => $devices
  end

  #def select
  #  uuid = params[:uuid]
  #  dev = Device.get_by_uuid(params[:uuid])
  #  #dev.select()
  #  render :json => { success: true }
  #end

  def volume_change
    dev = Device.get_by_uuid(params[:uuid])
    #dev.select()
    dev.set_volume(params[:volume_level].to_f)
    # Note: the above broadcasts the volume changes to anyone connected to the web app

    render :json => { success: true }
  end

end