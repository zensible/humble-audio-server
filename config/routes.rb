Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'

  mount ActionCable.server => '/cable'

  get '/template/:template_name' => 'home#template'

  scope '/api' do
    scope '/devices' do
      get '/refresh' => 'devices#refresh'
      get '/get_all' => 'devices#get_all'
      get '/select/:uuid' => 'devices#select'
      get '/volume_change/:uuid/:volume_level' => 'devices#volume_change', :constraints => { :volume_level => /\d\.\d+/ }
      get '/play_status/:uuid' => 'devices#play_status'
    end

    scope '/presets' do
      post '/create' => 'presets#create'
      get '/get_all' => 'presets#index'
      get '/destroy/:id' => 'presets#destroy'
      get '/play/:id' => 'presets#play'
    end

    scope '/mp3s' do
      get '/get/:mode/:id' => 'mp3s#get'
      get '/get_folders/:mode/:folder_id' => 'mp3s#get_folders'
      get '/refresh/:mode' => 'mp3s#refresh'
      post '/play' => 'mp3s#play'
      get '/stop/:cast_uuid' => 'mp3s#stop'
      get '/pause/:cast_uuid' => 'mp3s#pause'
      get '/resume/:cast_uuid' => 'mp3s#resume'
      get '/next/:cast_uuid' => 'mp3s#next'
      get '/prev/:cast_uuid' => 'mp3s#prev'
    end
  end

end
