multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Media, Preset) {

  // For use in debugging w/ the chrome console
  window.scope = $scope;

  // If false, show the loading indicator. If true, show the UI
  $scope.loaded = false;

  $scope.available_modes = window.menu;

  function init() {
    $scope.home = {
      devices: [],  // All devices
      device: null, // Currently selected device
      devices_loaded: false,  // If false, show loading gif
      mode: "",  // Currently selected mode
      folder_id: -1,  // Currently selected folder id
      folder: {},  // Currently selected folder
      mp3s: [],  // Mp3s in current folder
      radio_stations: [],  // All radio stations
      radio_station: ""  // Currently selected radio station
    }

    var browser = jQuery.browser;

    // 'device' for when we're playing MP3s in the browser rather than on a chromecast
    $scope.browser_device = {
      cast_type: 'audio',
      uuid: 'browser',
      volume_level: 90,
      friendly_name: "Local Play (" + toTitleCase(browser.name) + " for " + toTitleCase(browser.platform) + ")",
      state_local: {
        folder_id: null,
        mp3: {},
        mp3_id: null,
        mp3_url: "",
        radio_station: "",
        repeat: "off",
        shuffle: "off"
      },
      player_status: "UNKNOWN",
      num_casting: 3
    }
    if (sessionStorage.getItem('browser_state_local')) {
      console.log("local", sessionStorage.getItem('browser_state_local'))
      $scope.browser_device.state_local = JSON.parse(sessionStorage.getItem('browser_state_local'))
      // If playing, start and seek to correct ms
    }
    if (sessionStorage.getItem('browser_volume_level')) {
      $scope.browser_device.volume_level = parseFloat(sessionStorage.getItem('browser_volume_level'))
    }
    setInterval(function() {
      sessionStorage.setItem('browser_state_local', JSON.stringify(get_state_local()))
      //console.log("JSON.stringify(get_state_local()", JSON.stringify(get_state_local()))
      sessionStorage.setItem('browser_volume_level', JSON.stringify($scope.browser_device.volume_level))
    }, 1000)

    // Subscribe to devices channel. This shares the state of the cast list between users: audio casts, groups and their volume levels
    App.cable.subscriptions.create('DeviceChannel', {
      connected: function() {
        console.log("Connected to ActionCable: DEVICE")
      },
      received: function(data) {
        console.log('DEVICES RECEIVED', JSON.parse(data))
        $scope.home.devices = JSON.parse(data || "{}")

        $scope.home.devices_loaded = true

        // Set default device / update it based on changes on the back-end (see: Device.broadcast())
        var default_cast_uuid = localStorage.getItem('cast_uuid') || 'browser';
        if (default_cast_uuid) {
          if (default_cast_uuid == 'browser') {
            $scope.select_cast($scope.browser_device, 'auto');
          } else {
            for (var i = 0; i < $scope.home.devices.length; i++) {
              var dev = $scope.home.devices[i];
              if (dev['uuid'] == default_cast_uuid) {
                // This will also update the device's state in the playbar (e.g. play time, shuffle/repeat, song name)
                $scope.select_cast(dev, 'auto')
              }
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
        $('#cast-select').css("height", ((1.7 * parseFloat(max)) + 2) + "em")

        // If we're here, enough has loaded that the page will look correct
        $scope.loaded = true;

        $scope.safeApply()
      },
      disconnected: function() {
        console.log("Disconnected!")
      },
      status: function() {
        console.log("STATUS")
      }
    });

    var mode = localStorage.getItem('mode') || 'music';
    if (mode) {
      $scope.select_mode(mode)
    }

    // Set up playbar. 
    init_playbar($scope, $rootScope, Media, Device);
    init_mp3_player($scope, $rootScope, Media, Device);
    init_presets($scope, $rootScope, Media, Device, Preset);
  }

  /*
   * User selected a chromecast from the device list, get its shared state if any
   */
  $scope.select_cast = function(device, auto_manual) {
    $scope.home.device = device;

    // These are not necessarily set if no one has played to this cast yet since the server started
    /*
    if (device.state_local && device.state_local.repeat) {
      $scope.home.repeat = device.state_local.repeat;
    }
    if (device.state_local && device.state_local.shuffle) {
      $scope.home.shuffle = device.state_local.shuffle;
    }
    */

    var setup_cast_ui = function(dev) {
      if (dev.state_local && dev.state_local.start && dev.player_status == "PLAYING") {
        var sl = dev.state_local
        if (sl['mp3']) {
          $scope.playbar.reset(sl['mp3']['length_seconds'] * 1000, sl['elapsed'] * 1000)
          $scope.playbar.play()
        }
      } else {
        // Nothing is playing or song is buffering
        $scope.playbar.reset(0, 0)
        $scope.playbar.stop()
      }
    }

    // select_cast was initiated by receiving websocket update. Info should be the very latest
    if (auto_manual == 'auto') {
      setup_cast_ui(device);
    }

    // select_cast was initiated by clicking a cast in the UI. Its elapsed time will be stale, so get an update from the back-end
    if (auto_manual == 'manual') {
      if (device.uuid == 'browser') {
        //setup_cast_ui($scope.browser_device)
      } else {
        Device.select_cast(device.uuid, function(response) {
          setup_cast_ui(response.data)
        })
      }
    }

    localStorage.setItem('cast_uuid', device.uuid);
  }

  /*
   * User clicked one of the 'modes' in the leftmost column: Presets, Music, Radio etc
   */
  $scope.select_mode = function(mode, callback) {
    console.log("mode", mode)
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
        //$scope.playbar.init($scope.home.mp3s)
        if (callback) { callback() }
      })
    }
    // These modes share a multi-level directory structure
    if (mode == 'music' || mode == 'spoken') {
      Media.get_folders(mode, -1, function(response) {
        $scope.home.folders = response.data;
        if (response.data.length == 0) {
          Media.get(mode, -1, function(response) {
            if (response.data.length == 0) {
              $.notify("No mp3s found. You may need to populate and/or refresh your media.", "warn")
            }
          })
        }
        Media.get(mode, -1, function(response) {
          $scope.home.mp3s = response.data
          if (callback) { callback() }
        })

        var folder_id = localStorage.getItem('folder::' + mode)
        if (folder_id > 0) {
          $scope.select_folder(folder_id);
        } else {
          $scope.select_folder(-1);
        }
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
    if (mode == 'radio') {
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
        //$scope.playbar.init($scope.home.mp3s)
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
    if (!$scope.home.device) {
      return;
    }
    return {
      cast_uuid: $scope.home.device.uuid,
      mode: $scope.home.mode,
      repeat: $scope.home.device.state_local.repeat,
      shuffle: $scope.home.device.state_local.shuffle,
      folder_id: $scope.home.folder_id
    }
  }

  /*
   * The user has clicked an MP3 in #selector2, in music/spoken/white-noise mode.
   * Construct a playlist of mp3 ids/urls and send it and the user's current UI state to mp3s_controller.rb#play
   */
  $scope.play = function(index, seekSecs) {
    console.log("play", index)
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
    for (var i = 0; i < mp3s.length; i++) {
      add_playlist(mp3s[i])
    }

    //$scope.playbar.pause()
    $scope.buffering = true;

    if ($scope.home.mode != "spoken" && $scope.home.mode != "music") {
      $scope.home.folder_id = -1
      $scope.home.folder = null
      $scope.home.folders = []
    }

    var hsh = get_state_local();
    hsh['seek'] = seekSecs;
    data = {
      state_local: hsh,
      playlist: playlist,
      playlist_index: index,
      seek: seekSecs
    };

    if ($scope.home.device.uuid == 'browser') {
      $scope.volume_change($scope.browser_device)

      // For playing in the browser it's easy, just start playing with a hidden jPlayer and update the playbar
      $scope.player_mp3.play_playlist(data)
    } else {
      // For chromecasts, we have to tell the back-end to load and play the playlist on the given device
      // We then depend on Device.broadcast() to fire when buffering/playing starts. See the init() and $scope.select_cast() functions
      Media.play(data, function(response) {
        $scope.buffering = false;
      })
    }
  }

  $scope.play_bookmark = function(bookmark) {
    Media.get_folder('spoken', $scope.home.folder_id, function(response) {
      var fol = response.data;
      var bookmark = fol['bookmark']

      mp3 = bookmark['mp3']
      var seekSecs = bookmark['elapsed']

      var mp3s = $scope.home.mp3s;
      var index = -1;
      for (var i = 0; i < mp3s.length; i++) {
        if (mp3s[i].id == mp3['id']) {
          index = i;
          break
        }
      }
      if (index == -1) {
        $.notify("The bookmarked MP3 no longer exists in this folder!")
      } else {
        $scope.play(index, seekSecs)
      }

    })
  }


  /*
   * The user has clicked a radio station in #selector2 in radio mode.
   * Construct a playlist of that station's mp3 url and send it and the user's current UI state to mp3s_controller.rb#play
   */
  $scope.play_radio = function(station) {
    $scope.home.mode = 'radio'
    $scope.home.radio_station = station
    $scope.home.folder_id = -1
    $scope.home.folder = null
    $scope.home.folders = []

    var sl = get_state_local();
    sl.radio_station = station;
    data = {
      state_local: sl,
      playlist: [ { id: -1, url: station.url } ],
      playlist_index: 0,
      seek: 0
    };
//home.device.state_local.mp3.title
    if ($scope.home.device.uuid == 'browser') {
      console.log("station", station)
      $scope.browser_device.state_local = sl;
      $scope.volume_change($scope.browser_device)
      // For playing in the browser it's easy, just start playing with a hidden jPlayer and update the playbar
      $scope.player_mp3.play_playlist(data)
    } else {
      Media.play(data, function(response) {
        $scope.buffering = false;
      })    
    }
  }

  $scope.stop_all = function() {
    $.notify("Stopping all chromecasts!", "warn")
    $scope.player_mp3.stop()
    Media.stop_all(function(response) {
      $scope.playbar.stop();
    })
  }

  var volume_timer;

  $scope.volume_change = function(device) {
    console.log("vc dev", device)
    if (!device) {
      return;
    }
    if (device.uuid == 'browser') {
      $('#jquery_jplayer_1').jPlayer("volume", device.volume_level)
      return;
    }
    console.log("device.volume_level", device.volume_level)
    clearTimeout(volume_timer);
    volume_timer = setTimeout(function() {  // Timeout prevents user from changing volume 10 times a second
      var val = device.volume_level;
      if (device.volume_level == 1) { val = "1.0" }
      if (device.volume_level == 0) { val = "0.0" }
      Device.volume_change(device.uuid, val, function() {
        console.log("yay")
      })
    }, 100)
  }

  // Determine if a given mode/folder/mp3 is being played. Works by checking device.state_local[fieldname] against 'val'.
  // This is used to show the play buttons throughout the GUI
  $scope.is_playing = function(type, val) {
    var devices = $scope.home.devices;
    //console.log("$scope.browser_device.state_local[type]", $scope.browser_device.state_local[type], "type", type, "val", val)
    if ($scope.browser_device.player_status == 'PLAYING' && $scope.browser_device.state_local[type] == val) {
      //console.log("YASS")
      return $scope.browser_device;
    }
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

  var dirname = $scope.dirname = function(str) {
    return str.replace(/\\/g,'/').replace(/\/[^\/]*$/, '');;
  }

  var basename = $scope.basename = function(str) {
     var base = new String(str).substring(str.lastIndexOf('/') + 1); 
      if(base.lastIndexOf(".") != -1)       
          base = base.substring(0, base.lastIndexOf("."));
     return base;
  }

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

    Media.refresh($scope.home.mode, function(response) {
      console.log("response", response.data)
      var stats = response.data;
      var str = "Done. ";
      if (stats.added > 0) {
        str += stats.added + " added. ";
      }
      if (stats.error > 0) {
        str += stats.error + " errors. ";
      }
      if (stats.moved > 0) {
        str += stats.moved + " moved. ";
      }
      if (stats.removed > 0) {
        str += stats.removed + " removed. ";
      }
      str += stats.total + " mp3s total.";
      $('.notifyjs-wrapper').trigger('notify-hide');
      $.notify(str)

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

  $scope.configure_group = function(device) {
    $('#overlay').show()
    $('#fade').show()
    $scope.group_configuring = device;
  }

  $scope.is_child = function(group, uuid) {
    if (!group) {
      return false;
    }
    var children = group.children;
    for (var i = 0; i < children.length; i++) {
      if (children[i] == uuid) {
        return true;
      }
    }
    return false;
  }

  $scope.group_configuration_save = function() {
    var arr = $('.config-checked');
    var children = []
    var group_uuid = $scope.group_configuring.uuid;
    for (var i = 0; i < arr.length; i++) {
      var checkbox = $(arr[i]);
      if (checkbox.is(':checked')) {
        children.push(checkbox.attr('uuid'))
      }
    }

    $scope.close_modal();

    Device.set_children({
      group: group_uuid,
      children: children
    }, function(response) {
      $.notify("Saved!")
    })
  }

  $scope.close_modal = function() {
    $('#overlay').hide()
    $('#fade').hide()
  }

  var cache = {}
  init()

});

