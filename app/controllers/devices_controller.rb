class DevicesController < ApiController

  def refresh
    # Wait until terminal is ready

    @devices = JSON.parse(PyChromecast.run($get_devices))
  end

  def get
    render :json => Device.get_all()
  end

  def select
    friendly_name = params[:friendly_name]
    Device.select(friendly_name)
    render :json => { success: true }
  end

  def volume_change
    friendly_name = params[:friendly_name]
    Device.select(friendly_name)
    Device.set_volume(params[:volume_level])
    render :json => { success: true }
  end

end