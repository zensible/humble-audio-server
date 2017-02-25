class DevicesController < ApiController
  skip_before_action :verify_authenticity_token, :only => [:set_children]

  def refresh
    # Wait until terminal is ready

    render :json => Device.refresh()
  end

  def get_all
    render :json => $devices
  end

  def select
    uuid = params[:uuid]
    dev = Device.get_by_uuid(params[:uuid])
    #dev.select()
    render :json => dev.to_h  
  end

  def volume_change
#    abort "uuid: #{params[:uuid]}"
    dev = Device.get_by_uuid(params[:uuid])
    #dev.select()

    dev.children.each do |child_uuid|
      child = Device.get_by_uuid(child_uuid)
      child.volume_level = params[:volume_level].to_f if child
    end

    dev.set_volume(params[:volume_level].to_f)
    # Note: the above broadcasts the volume changes to anyone connected to the web app

    render :json => { success: true }
  end

  def shuffle_change
    dev = Device.get_by_uuid(params[:uuid])

    dev.set_shuffle(params[:shuffle])

    render :json => { success: true }
  end

  def repeat_change
    dev = Device.get_by_uuid(params[:uuid])

    dev.set_repeat(params[:repeat])

    render :json => { success: true }
  end

  def set_children
    group_uuid = params[:group]
    children = params[:children]
    $redis.hset("group_children", group_uuid, JSON.dump(children))
    Device.broadcast()
  end

end