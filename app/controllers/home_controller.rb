class HomeController < ApplicationController
  require 'expect'
  require 'pty'

  include PythonHelper

  def index

  end

  def refresh_devices
    # Wait until terminal is ready
    @get_devices = "
      chromecasts = pychromecast.get_chromecasts()
      arr = [cc.device.friendly_name for cc in chromecasts]
      print(json.dumps(arr))
    "

    @devices = JSON.parse(run_py(@get_devices))
  end

  def template
    template_name = params[:template_name]

    render "templates/#{template_name}", locals: {  }, :layout => nil
  end

end
