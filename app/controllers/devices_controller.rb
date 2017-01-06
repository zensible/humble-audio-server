class DevicesController < ApiController

  def refresh
    # Wait until terminal is ready

    @devices = Device.refresh()
    render :json => @devices
  end

  def get
    render :json => Device.get_all()
  end

  def select
    uuid = params[:uuid]
    Device.select(uuid)
    render :json => { success: true }
  end

  def volume_change
    uuid = params[:uuid]
    Device.select(uuid)
    Device.set_volume(params[:volume_level])
    render :json => { success: true }
  end

end