
multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Media) {

  window.scope = $scope;

  var autosize = function() {
    //$('#top').css('height', ($(window).height()+"px"))
  }
  autosize();

  $(window).resize(function() {
    autosize()
  })

  RegExp.escape = function( value ) {
    return value.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
  }

  $scope.getMedia = function(mode, id, callback) {
    Media.get(mode, -1, function(response) {
      /*
      if (response.data.length == 0) {
        Media.refresh(mode, function(response) {
          var stats = response.data['stats']
          Media.get(mode, function(response) {
            $scope.home.media = response.data
          })
        })
      } else {
      */
      $scope.home.media = response.data
      $scope.player.init($scope.home.media)
    })
  }

  $scope.selectMode = function(mode) {
    //if ($scope.home.mode == 'mode') { return; }
    $scope.home.mode = mode

    $scope.home.media = [];

    if (mode == 'white-noise') {
      $scope.getMedia('white-noise', -1, function() {
        console.log("DONE")
      })
    }
    if (mode == 'music') {
      Media.get_folders(function(response) {
        $scope.home.folders = response.data
      })
    }
    if (mode == 'radio') {
      Media.get_radio(function(response) {
        $scope.home.radio_stations = response.data;
        console.log(response)
      })
    }
  }

  $scope.get_media_folder = function(folder) {
    var id = folder.id;
    $scope.home.state_local.folder = folder.id;
    Media.get('music', id, function(response) {
      /*
      if (response.data.length == 0) {
        Media.refresh(mode, function(response) {
          var stats = response.data['stats']
          Media.get(mode, function(response) {
            $scope.home.media = response.data
          })
        })
      } else {
      */
      $scope.home.media = response.data
      $scope.player.init($scope.home.media)
    })    
  }

  $scope.play_radio = function(station) {
    Media.play({ urls: [ station.url ] }, function(response) {
      $scope.buffering = false;

      // Buffering complete.
      $scope.player.playing = true;

      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })    
  }

  $scope.play = function(index) {
    //var mp3 = $scope.home.media[index];

    public_prefix = dirname(audio_dir)
    url_prefix = 'http://192.168.0.103:3000'

    var regex = new RegExp(RegExp.escape(public_prefix));

    var playlist = []
    var mp3s = $scope.home.media;

    function add_playlist(mp3) {
      var path = mp3['path'];
      url = url_prefix + encodeURI(path.replace(regex, ''))
      url = url.replace(/'/g, '%27')

      playlist.push({
        id: mp3.id,
        url: url
      });
    }
    for (var i = index; i < mp3s.length; i++) {
      add_playlist(mp3s[i])
    }
    for (var i = 0; i < index; i++) {
      add_playlist(mp3s[i])
    }

    $scope.player.pause()
    $scope.buffering = true;

    // Buffering begins...
    var item = $scope.playlist.items[index];
    $scope.playlist.current_index = index;
    $scope.playlist.current_item = item;

    var mode = $scope.home.mode;
    data = {
      state_local: $scope.home.state_local,
      playlist: playlist
    };

    Media.play(data, function(response) {
      $scope.buffering = false;
      // Buffering complete.
      $scope.player.play(index, 0, function() { })
      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })
  }

  $scope.prev = function() {
    Media.prev()
  }

  $scope.next = function() {
    Media.next()
  }

  $scope.toggleRepeat = function() {
    switch ($scope.home.state_local.repeat) {
      case "off":
        $scope.home.state_local.repeat = "all";
        break;
      case "all":
        $scope.home.state_local.repeat = "one";
        break;
      case "one":
        $scope.home.state_local.repeat = "off";
        break;
    }
  }

  $scope.toggleShuffle = function() {
    if ($scope.home.state_local.shuffle == "on") {
      $scope.home.state_local.shuffle = "off";
    } else {
      $scope.home.state_local.shuffle = "on";
    }
  }

  $scope.stop = function() {
    Media.stop()
  }

  $scope.pause = function() {
    Media.pause(function(response) {
      $scope.player.pause()
    })
  }

  $scope.resume = function() {
    Media.resume(function(response) {
      $scope.player.resume()
    })
  }

  var timer;

  $scope.volume_change = function(device) {
    clearTimeout(timer);
    timer = setTimeout(function() {
      var val = device.volume_level;
      if (device.volume_level == 1) { val = "1.0" }
      if (device.volume_level == 0) { val = "0.0" }
      Device.volume_change(device.friendly_name, val)
    }, 100)
  }

  var dirname = $scope.dirname = function(str) {
    return str.replace(/\\/g,'/').replace(/\/[^\/]*$/, '');;
  }

  var basename = $scope.basename = function(str) {
     var base = new String(str).substring(str.lastIndexOf('/') + 1); 
      if(base.lastIndexOf(".") != -1)       
          base = base.substring(0, base.lastIndexOf("."));
     return base;
  }

  init_player($scope, $rootScope);

  $scope.refresh_media = function() {
    Media.refresh($scope.home.mode, function() {
      $scope.selectMode($scope.home.mode);
    })
  }

  $scope.select_cast = function(device) {
    Device.select_cast(device.friendly_name)
    $scope.home.device = device;
  }

  var cache = {}

  $scope.home = {
    mode: '',
    devices: [],
    selector1: [],
    selector2: [],
    media: [],
    radio_stations: [],
    device: null,
    state_local: {
      player_state: "IDLE",
      mode: "",
      repeat: "off",  // off, all, one
      shuffle: "off",
      folder: -1,
      playlist: -1,
      mp3: {},
      radio: "",
      volumes: {}
    },
    state_shared: { // shared state
      player_state: "IDLE",
      mode: "",
      repeat: "off",  // off, all, one
      shuffle: "off",
      folder: "",
      playlist: "",
      mp3: {},
      radio: "",
      volumes: {}
    }
  }

  Device.get(function(response) {
    $scope.home.devices = response.data

    for (var i = 0; i < $scope.home.devices.groups.length; i++) {
      var device = $scope.home.devices.groups[i]
      if (device.friendly_name == window.cur_cast) {
        $scope.home.device = device;
      }
    }
    for (var i = 0; i < $scope.home.devices.audios.length; i++) {
      var device = $scope.home.devices.audios[i]
      if (device.friendly_name == window.cur_cast) {
        $scope.home.device = device;
      }
    }

  })

  App.cable.subscriptions.create('StateChannel', {
    connected: function() {
      console.log("Connected to ActionCable")
    },
    received: function(data) {
      console.log("DATAAA", data)
    },
    disconnected: function() {
      console.log("Disconnected!")
    },
    status: function() {
      alert(5)
      console.log("STATUS")
    }
  });


  $scope.selectMode('music')
});

