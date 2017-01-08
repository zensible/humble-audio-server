class HomeController < ApplicationController

  def index
  end

  def template
    template_name = params[:template_name]

    render "templates/#{template_name}", locals: {  }, :layout => nil
  end

end
