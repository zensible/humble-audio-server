Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'

  mount ActionCable.server => '/cable'

  get '/template/:template_name' => 'home#template'

  scope '/api' do
    scope '/devices' do
      get '/refresh' => 'devices#refresh'
      get '/get' => 'devices#get'
      get '/select/:uuid' => 'devices#select'
      get '/volume_change/:uuid/:volume_level' => 'devices#volume_change', :constraints => { :volume_level => /\d\.\d+/ }
    end

    scope '/mp3s' do
      get '/get/:mode/:id' => 'mp3s#get'
      get '/get_folders' => 'mp3s#get_folders'
      get '/refresh/:mode' => 'mp3s#refresh'
      post '/play' => 'mp3s#play'
      get '/stop' => 'mp3s#stop'
      get '/pause' => 'mp3s#pause'
      get '/resume' => 'mp3s#resume'
      get '/next' => 'mp3s#next'
      get '/prev' => 'mp3s#prev'
    end
  end

end
