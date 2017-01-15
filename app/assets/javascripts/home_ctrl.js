multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Media, Preset) {

  window.scope = $scope;

  function init() {
    $scope.home = {
      devices: [],
      device: null,
      devices_loaded: false,
      mp3s: [],
      radio_stations: [],
      mode: "",
      folder_id: -1,
      folder: {},
      radio_station: "",
      repeat: "off",
      shuffle: "off"
    }

    // Get devices, set current device if any

    // Subscribe to devices channel. This shares the state of the cast list between users: audio casts, groups and their volume levels
    App.cable.subscriptions.create('DeviceChannel', {
      connected: function() {
        console.log("Connected to ActionCable: DEVICE")
      },
      received: function(data) {
        console.log('DEVICES RECEIVED', JSON.parse(data))
        $scope.home.devices = JSON.parse(data || "{}")

        $scope.home.devices_loaded = true

        // Set default device
        var default_cast_uuid = localStorage.getItem('cast_uuid');
        if (default_cast_uuid) {
          for (var i = 0; i < $scope.home.devices.length; i++) {
            var dev = $scope.home.devices[i];
            if (dev['uuid'] == default_cast_uuid) {
              $scope.select_cast(dev, 'auto')
            }
          }
        }

        // Auto-resize the list of devices: 24px per row
        var num_groups = 0;
        var num_audios = 0;
        for (var i = 0; i < $scope.home.devices.length; i++) {
          var dev = $scope.home.devices[i];
          if (dev['cast_type'] == 'group') {
            num_groups += 1;
          } else {
            num_audios += 1;
          }
        }

        var max = num_groups;
        if (num_audios > max) { max = num_audios; }
        $('#cast-select').css("height", (30 * max) + "px")

        $scope.safeApply()
      },
      disconnected: function() {
        console.log("Disconnected!")
      },
      status: function() {
        console.log("STATUS")
      }
    });

    var mode = localStorage.getItem('mode');
    if (mode) {
      $scope.select_mode(mode || 'music')
    }
  }

  // Determine if a given mode/folder/mp3 is being played. Works by checking device.state_local[fieldname] against 'val'.
  // This is used to show the play buttons throughout the GUI
  $scope.is_playing = function(type, val) {
    var devices = $scope.home.devices;
    for (var i = 0; i < devices.length; i++) {
      var dev = devices[i];
      if (dev.player_status != "IDLE" && dev.player_status != "UNKNOWN") {
        //console.log("dev.state_local[type]", dev.state_local[type], "type", type, "val", val)
        if (dev.state_local[type] == val) {
          //console.log("YES")
          return dev;
        }
      }
    }
    return false;
  }

  /*
   * User clicked one of the 'modes' in the leftmost column: Presets, Music, Radio etc
   */
  $scope.select_mode = function(mode, callback) {
    localStorage.setItem('mode', mode);

    $scope.home.mode = mode

    $scope.home.mp3s = [];

    if (mode == 'presets') {
      Preset.get_all(function(response) {
        $scope.home.presets = response.data;
        if ($scope.home.presets.length == 0) {
          $.notify("No presets found. Try playing some audio and click", "warn")
        }
        console.log(response)
      })
      if (callback) { callback() }
    }
    // White noise mode is essentially a single directory, as opposed to mult-level like music/spokens
    if (mode == 'white-noise') {
      Media.get('white-noise', -1, function(response) {
        if (response.data.length == 0) {
          $.notify("No mp3s found in this folder. You may need to populate and/or refresh your media.", "warn")
        }
        $scope.home.mp3s = response.data
        //$scope.player.init($scope.home.mp3s)
        if (callback) { callback() }
      })
    }
    // These modes share a multi-level directory structure
    if (mode == 'music' || mode == 'spoken') {
      Media.get_folders(mode, -1, function(response) {
        $scope.home.folders = response.data;
        if (response.data.length == 0) {
          $.notify("No mp3s found. You may need to populate and/or refresh your media.", "warn")
        }

        var folder_id = localStorage.getItem('folder::' + mode)
        if (folder_id) {
          $scope.select_folder(folder_id);
        } else {
          $scope.select_folder(-1);
        }

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

  /*
   * In music/spoken mode, user clicked a folder name or 'Back' in #selector1
   *
   * Alternatively, called by select_mode to select the most recently-selected folder
   */
  $scope.select_folder = function(folder_id) {
    localStorage.setItem('folder::' + $scope.home.mode, folder_id);

    $scope.home.folder_id = folder_id;
    $scope.home.folder = {};
    for (var i = 0; i < $scope.home.folders.length; i++) {
      var fol = $scope.home.folders[i];
      if (fol.id == $scope.home.folder_id) {
        $scope.home.folder = fol;
      }      
    }

    Media.get($scope.home.mode, folder_id, function(response) {
      if (response.data.length > 0) {
        $scope.home.mp3s = response.data
        //$scope.player.init($scope.home.mp3s)
      } else {
        $scope.home.mp3s = []
      }
    })
  }

  /*
   * The UI state when a user clicked an MP3 to play it.
   * 
   * This gets attached to the device (see mp3s_controller.rb#play) so that cast's background thread knows how to repeat etc.
   * It is also broadcast to all other users via websockets (see device.rb#broadcast), to be used by the front-end UI for showing play buttons on the appropriate cast/mode/folder/mp3 entry
   */
  function get_state_local() {
    return {
      cast_uuid: $scope.home.device.uuid,
      mode: $scope.home.mode,
      repeat: $scope.home.repeat,
      shuffle: $scope.home.shuffle,
      folder_id: $scope.home.folder_id,
      radio_station: $scope.home.radio_station
    }
  }

  /*
   * The user has clicked an MP3 in #selector2, in music/spoken/white-noise mode.
   * Construct a playlist of mp3 ids/urls and send it and the user's current UI state to mp3s_controller.rb#play
   */
  $scope.play = function(index) {
    public_prefix = dirname(audio_dir)
    url_prefix = window.http_address

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

    //$scope.player.pause()
    $scope.buffering = true;

    if ($scope.home.mode != "spoken" && $scope.home.mode != "music") {
      $scope.home.folder_id = -1
      $scope.home.folder = null
      $scope.home.folders = []
    }

    // Buffering begins...
    /*
    var item = $scope.playlist.items[index];
    $scope.playlist.current_index = index;
    $scope.playlist.current_item = item;
    */

    data = {
      state_local: get_state_local(),
      playlist: playlist
    };

    Media.play(data, function(response) {
      $scope.buffering = false;
      // Buffering complete.
      //$scope.player.play(index, 0, function() { })
      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })
  }

  /*
   * The user has clicked a radio station in #selector2 in radio mode.
   * Construct a playlist of that station's mp3 url and send it and the user's current UI state to mp3s_controller.rb#play
   */
  $scope.play_radio = function(station) {
    $scope.home.mode = 'radio'
    $scope.home.radio_station = station.url
    $scope.home.folder_id = -1
    $scope.home.folder = null
    $scope.home.folders = []

    data = {
      state_local: get_state_local(),
      playlist: [ { id: -1, url: station.url } ]
    };
    Media.play(data, function(response) {
      $scope.buffering = false;

      // Buffering complete.
      //$scope.player.playing = true;

      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })    
  }

  /*
   * Go back one entry in the playlist
   */
  $scope.prev = function() {
    Media.prev($scope.home.device.uuid)
  }

  /*
   * Go forward one entry in the playlist
   */
  $scope.next = function() {
    Media.next($scope.home.device.uuid)
  }

  $scope.toggleRepeat = function() {
    switch ($scope.home.repeat) {
      case "off":
        $scope.home.repeat = "all";
        break;
      case "all":
        $scope.home.repeat = "one";
        break;
      case "one":
        $scope.home.repeat = "off";
        break;
    }
  }


  $scope.toggleShuffle = function() {
    if ($scope.home.shuffle == "on") {
      $scope.home.shuffle = "off";
    } else {
      $scope.home.shuffle = "on";
    }
  }

  /*
  $scope.stop = function() {
    Media.stop($scope.home.device.uuid)
  }
  */

  $scope.pause = function() {
    Media.pause($scope.home.device.uuid, function(response) {
      $scope.player.pause()
    })
  }

  $scope.resume = function() {
    Media.resume($scope.home.device.uuid, function(response) {
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

  $scope.preset_create = function() {
    name = window.prompt("Please enter a playlist name", "");
    if (name) {
      Preset.create({ "name": name }, function(response) {
        Preset.get_all(function(response) {
          $scope.home.presets = response.data;
        })
      })
    }
  }

  $scope.play_preset = function(id) {
    Preset.play(id)
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

  $scope.is_anything_playing = function() {
    for (var i = 0; i < $scope.home.devices.length; i++) {
      if ($scope.home.devices[i].player_status == 'PLAYING') {
        return true;
      }
    }
    return false;
  }

  $scope.refresh_media = function() {
    $.notify("Beginning sync. This can take several minutes depending on how many new MP3s are found.", "error")

    Media.refresh($scope.home.mode, function() {
      $scope.select_mode($scope.home.mode);
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

  $scope.select_cast = function(device, auto_manual) {
    $scope.home.device = device;
    $scope.home.repeat = device.state_local.repeat;
    $scope.home.shuffle = device.state_local.shuffle;

    var setup_cast_ui = function(dev) {
      if (dev.state_local && dev.state_local.start) {
        var sl = dev.state_local
        $scope.player.reset(sl['mp3']['length_seconds'] * 1000, sl['elapsed'] * 1000)
        $scope.player.play()
      } else {
        $scope.player.reset(0, 0)
        $scope.player.stop()
      }
    }

    // select_cast was initiated by receiving websocket update. Info should be the very latest
    if (auto_manual == 'auto') {
      setup_cast_ui(device);
    }

    // select_cast was initiated by clicking a cast in the UI. Its elapsed time will be stale, so get an update from the back-end
    if (auto_manual == 'manual') {
      Device.select_cast(device.uuid, function(response) {
        setup_cast_ui(response.data)
      })
    }

    localStorage.setItem('cast_uuid', device.uuid);
  }

  var cache = {}
  init()

});

