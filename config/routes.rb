Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'

  get '/template/:template_name' => 'home#template'

  get '/api/refresh_devices' => 'home#refresh_devices'
  get '/api/get_devices' => 'home#get_devices'

  get '/api/refresh_media/:mode' => 'home#refresh_media'
  get '/api/get_media/:mode' => 'home#get_media'

  post '/api/play_media' => 'home#play_media'
  get '/api/stop_media' => 'home#stop_media'
  get '/api/pause_media' => 'home#pause_media'
  get '/api/select_cast/:friendly_name' => 'home#sel_cast'

end
