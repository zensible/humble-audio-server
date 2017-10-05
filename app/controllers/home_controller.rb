class HomeController < ApplicationController

  # Renders a blank page with the application.html.haml layout. Its ng-app and ng-controller attributes bootstrap the application and call template, below
  def index
    #if File.exist?("config/theme_selected.txt")
    #  @theme_selected = File.read("config/theme_selected.txt") || "night" 
    #else
    #  @theme_selected = "night"
    #end

    #$themes = YAML.load_file(Rails.root + 'config/themes.yml')
    #$theme = $themes[@theme_selected]
  end

  # Since the app is a one-pager, this only renders views/templates/home.html.haml
  def template
    template_name = params[:template_name]

    render "templates/#{template_name}", locals: {  }, :layout => nil
  end

end
