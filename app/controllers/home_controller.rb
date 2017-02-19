class HomeController < ApplicationController

  # Renders a blank page with the application.html.haml layout. Its ng-app and ng-controller attributes bootstrap the application and call template, below
  def index
  end

  # Since the app is a one-pager, this only renders views/templates/home.html.haml
  def template
    template_name = params[:template_name]

    render "templates/#{template_name}", locals: {  }, :layout => nil
  end

end
