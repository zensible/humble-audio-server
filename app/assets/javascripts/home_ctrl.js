multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Media) {

  function init() {
    $scope.home = {
      mode: '',
      devices: [],
      device: null,
      devices_loaded: false,
      mp3s: [],
      radio_stations: []
    }

    // 
    $scope.state_local = {
      player_state: "IDLE",
      mode: "",
      repeat: "off",  // off, all, one
      shuffle: "off",
      folder_id: -1,
      playlist: -1,
      mp3: {},
      radio_station: "",
      volumes: {}
    }

    $scope.state_shared = { // shared state
      playing: [],
      volumes: {}
    }

    // Get devices, set current device if any
    Device.get_all(function(response) {
      $scope.home.devices = response.data
      $scope.home.devices_loaded = true

      for (var i = 0; i < $scope.home.devices.groups.length; i++) {
        var device = $scope.home.devices.groups[i]
        if (device.uuid == window.cur_cast) {
          $scope.home.device = device;
        }
      }
      for (var i = 0; i < $scope.home.devices.audios.length; i++) {
        var device = $scope.home.devices.audios[i]
        if (device.uuid == window.cur_cast) {
          $scope.home.device = device;
        }
      }
      var max = $scope.home.devices.groups.length;
      if ($scope.home.devices.audios.length > max) { max = $scope.home.devices.audios.length; }
      $('#cast-select').css("height", (24 * 4) + "px")
    })

    // Subscribe to state channel
    App.cable.subscriptions.create('StateChannel', {
      connected: function() {
        console.log("Connected to ActionCable")
      },
      received: function(data) {
        console.log("got state: " + data)
        $scope.state_shared = JSON.parse(data || "[]")
        $scope.safeApply()
      },
      disconnected: function() {
        console.log("Disconnected!")
      },
      status: function() {
        alert(5)
        console.log("STATUS")
      }
    });

    var mode = localStorage.getItem('mode');
    if (mode) {
      $scope.selectMode(mode || 'music')
    }
  }

  $scope.is_playing = function(type, val) {
    console.log("type", type, "val", val)
       /*
[{
  "cast_uuid": "1bb851ea-5b0a-fce7-f395-16e1e13a86b9",
  "mode": "music",
  "folder_id": 225,
  "radio_station": "",
  "mp3_id": 2508,
  "mp3_url": "http://192.168.0.103:3000/audio/music/!flerg/Mellow%20Gold%20-%2001%20-%20loser.mp3"
}]
*/    
    var shared = $scope.state_shared;
    for (var i = 0; i < shared.length; i++) {
      console.log(type, shared[type], val)
      var cast = shared[i];
      if (cast[type] == val) {
        return true;
      }
    }
    return false;
  }

  function set_default_music_folder() {
    var folder_id = localStorage.getItem('folder::music')
    for (var i = 0; i < $scope.home.folders.length; i++) {
      var fold = $scope.home.folders[i];
      if (fold.id == parseInt(folder_id)) {
        $scope.select_folder(fold)
      }
    }
  }

  $scope.selectMode = function(mode, callback) {
    localStorage.setItem('mode', mode);

    $scope.home.mode = mode

    $scope.home.mp3s = [];

    if (mode == 'white-noise') {
      Media.get('white-noise', -1, function(response) {
        if (response.data.length == 0) {
          $.notify("No mp3s found in this folder. You may need to populate and/or refresh your media.", "warn")
        }
        $scope.home.mp3s = response.data
        $scope.player.init($scope.home.mp3s)
        if (callback) { callback() }
      })
    }
    if (mode == 'music') {
      Media.get_folders(function(response) {
        $scope.home.folders = response.data;
        if (response.data.length == 0) {
          $.notify("No mp3s found. You may need to populate and/or refresh your media.", "warn")
        }
        set_default_music_folder()
        if (callback) { callback() }
      })
    }
    if (mode == 'radio') {
      Media.get_radio(function(response) {
        $scope.home.radio_stations = response.data;
        if ($scope.home.radio_stations.length == 0) {
          $.notify("No radio stations found. Please configure public/audio/radio.json", "warn")
        }
        console.log(response)
      })
      if (callback) { callback() }
    }
  }

  $scope.select_folder = function(folder) {
    if (!folder) { return; }
    localStorage.setItem('folder::' + $scope.home.mode, folder.id);

    var id = folder.id;
    $scope.state_local.folder_id = folder.id;
    Media.get('music', id, function(response) {
      $scope.home.mp3s = response.data
      $scope.player.init($scope.home.mp3s)
    })    
  }

  $scope.play_radio = function(station) {
    data = {
      state_local: $scope.state_local,
      playlist: [ { id: -1, url: station.url } ]
    };
    Media.play(data, function(response) {
      $scope.buffering = false;

      // Buffering complete.
      $scope.player.playing = true;

      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })    
  }

  $scope.play = function(index) {
    //var mp3 = $scope.home.mp3s[index];

    public_prefix = dirname(audio_dir)
    url_prefix = 'http://192.168.0.103:3000'

    var regex = new RegExp(RegExp.escape(public_prefix));

    var playlist = []
    var mp3s = $scope.home.mp3s;

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
    $scope.state_local.mode = mode
    data = {
      state_local: $scope.state_local,
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
    switch ($scope.state_local.repeat) {
      case "off":
        $scope.state_local.repeat = "all";
        break;
      case "all":
        $scope.state_local.repeat = "one";
        break;
      case "one":
        $scope.state_local.repeat = "off";
        break;
    }
  }

  $scope.toggleShuffle = function() {
    if ($scope.state_local.shuffle == "on") {
      $scope.state_local.shuffle = "off";
    } else {
      $scope.state_local.shuffle = "on";
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
      Device.volume_change(device.uuid, val)
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

  $scope.refresh_devices = function() {
    Device.refresh(function(response) {
      $scope.home.devices = response.data;
      if (response.data.audios.length == 0 && response.data.audios.groups.length == 0) {
        $.notify("No chromecast audio devices or groups found!", "error")
      }
    })
  }

  $scope.select_cast = function(device) {
    Device.select_cast(device.uuid)
    $scope.home.device = device;
  }

  var cache = {}
  init()

});

