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
    dev = Device.new(uuid)
    dev.select()
    render :json => { success: true }
  end

  def volume_change
    dev = Device.new(params[:uuid])
    dev.select()
    dev.set_volume(params[:volume_level].to_f)
    # Note: the above broadcasts the volume changes to anyone connected to the web app

    render :json => { success: true }
  end

end