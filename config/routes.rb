Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'

  get '/template/:template_name' => 'home#template'

  get '/api/refresh_devices' => 'home#refresh_devices'
  get '/api/get_devices' => 'home#get_devices'

end
