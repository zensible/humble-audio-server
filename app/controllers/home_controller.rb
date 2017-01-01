class HomeController < ApplicationController
  require 'expect'
  require 'pty'

  include PythonHelper

  def index

  end

  def refresh_devices
    # Wait until terminal is ready

    @devices = JSON.parse(run_py($get_devices))
  end

  def get_devices
    devices = $redis.get("devices")
    if devices.blank?
      refresh_devices()
      devices = $redis.get("devices")
    end
    render :json => devices
  end

  def template
    template_name = params[:template_name]

    render "templates/#{template_name}", locals: {  }, :layout => nil
  end

end
