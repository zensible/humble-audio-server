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
      get '/shuffle_change/:uuid/:shuffle' => 'devices#shuffle_change'
      get '/repeat_change/:uuid/:repeat' => 'devices#repeat_change'
      get '/play_status/:uuid' => 'devices#play_status'
      post '/set_children' => 'devices#set_children'
    end

    scope '/presets' do
      post '/create' => 'presets#create'
      get '/get_all' => 'presets#index'
      get '/destroy/:id' => 'presets#destroy'
      get '/play/:id' => 'presets#play'
      put '/update' => 'presets#update'
    end

    scope '/mp3s' do
      get '/index/:mode/:id' => 'mp3s#index'
      get '/:id' => 'mp3s#get_by_id', :constraints => { :id => /\d+/ }
      get '/get_folders/:mode/:folder_id' => 'mp3s#get_folders'
      get '/get_folder/:mode/:folder_id' => 'mp3s#get_folder'
      get '/refresh/:mode' => 'mp3s#refresh'
      post '/play' => 'mp3s#play'
      get '/stop/:cast_uuid' => 'mp3s#stop'
      get '/stop_all' => 'mp3s#stop_all'
      get '/pause/:cast_uuid' => 'mp3s#pause'
      get '/resume/:cast_uuid' => 'mp3s#resume'
      get '/save_bookmark/:mp3_id/:elapsed' => 'mp3s#save_bookmark'
      get '/next/:cast_uuid' => 'mp3s#next'
      get '/prev/:cast_uuid' => 'mp3s#prev'
      get '/seek/:cast_uuid/:secs' => 'mp3s#seek'
    end
  end

end
