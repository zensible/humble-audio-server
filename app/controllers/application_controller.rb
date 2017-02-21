class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  if $settings['login_username'] && $settings['login_password']
    http_basic_authenticate_with name: $settings['login_username'], password: $settings['login_password']
  end

end
