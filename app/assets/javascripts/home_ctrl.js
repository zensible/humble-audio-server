
/*
 * Home controller:
 *
 * This is the main interface. Selects mode (at left), folders and mp3s
 *
 * Also has the API for controlling device volume, CCA groups, etc
 *
 * It has several children which are on the same scope:
 *
 * init_playbar.js
 * init_mp3_player.js
 * init_preset.js
 *
 */
multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Mp3, Preset) {

  // For use in debugging w/ the chrome console
  window.scope = $scope;

  // If false, show the loading indicator. If true, show the UI
  $scope.loaded = false;

  $scope.available_modes = window.menu;

  function init() {
    // Init UI state
    $scope.home = {
      mode_ui: "",  // Currently selected mode in the UI (as opposed to a device)
      devices: [],  // All devices
      device_selected: null, // Currently selected device
      folder: {},  // Currently selected folder
      mp3s: [],  // Mp3s in current folder
      mp3_sort: "track_nr",
      mp3_sort_filename: false,
      radio_stations: [],  // All radio stations
      radio_station: "",  // Currently selected radio station
      sync_data: {}
    }

    // Init browser-play state

    // browser_device is for when we're playing MP3s in the browser rather than on a chromecast
    // See: mp3_player_init.js
    var browser_info = jQuery.browser;

    $scope.browser_device = {
      cast_type: 'audio',
      uuid: 'browser',
      volume_level: 90,
      friendly_name: "Local Play (" + toTitleCase(browser_info.name) + " for " + toTitleCase(browser_info.platform) + ")",
      // The state the UI was in when 'play' was clicked:
      state_local: {
        mode: "",
        folder: {},
        mp3: {},
        radio_station: "",
        repeat: "off",
        shuffle: "off"
      },
      player_status: "UNKNOWN",
      num_casting: 3
    }
    if (sessionStorage.getItem('browser_state_local')) {
      $scope.browser_device.state_local = JSON.parse(sessionStorage.getItem('browser_state_local'))
    }
    if (sessionStorage.getItem('browser_volume_level')) {
      $scope.browser_device.volume_level = parseFloat(sessionStorage.getItem('browser_volume_level'))
    }

    // Subscribe to devices channel. This shares the state of the cast list between users: audio casts, groups and their volume levels
    App.cable.subscriptions.create('DeviceChannel', {
      connected: function() {
        console.log("Connected to ActionCable: DEVICE")
      },
      received: function(data) {
        console.log('DEVICES RECEIVED', data)
        $scope.home.devices = JSON.parse(data || "{}")

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

        /*
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
        //$('#cast-select').css("height", ((1.7 * parseFloat(max)) + 2) + "em")
        */

        setInterval(function() {
          sessionStorage.setItem('browser_state_local', JSON.stringify($scope.home.device_selected.state_local))
          sessionStorage.setItem('browser_volume_level', JSON.stringify($scope.browser_device.volume_level))
        }, 1000)

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

    App.cable.subscriptions.create('SyncChannel', {
      connected: function() {
        console.log("Connected to ActionCable: SYNC")
      },
      received: function(data) {
        $scope.home.sync_data = data;
        $scope.home.sync_data.percentage = parseInt(parseFloat(data['current'] || 0) / parseFloat(data['total'] || 100) * 100) + "%"
        $scope.safeApply()
      },
      disconnected: function() {
        console.log("Disconnected!")
      },
      status: function() {
        console.log("STATUS")
      }
    });

    $scope.select_mode(localStorage.getItem('mode') || $scope.available_modes[0])

    // Set up playbar. 
    init_playbar($scope, $rootScope, Mp3, Device);
    init_mp3_player($scope, $rootScope, Mp3, Device);
    init_presets($scope, $rootScope, Mp3, Device, Preset);
  }

  /*
   * User selected a chromecast from the device list, get its shared state if any
   */
  $scope.select_cast = function(device, auto_manual) {
    $scope.home.device_selected = device;

    var setup_playbar = function(dev) {
      if (dev.state_local && (dev.state_local.start || dev.uuid == 'browser') && dev.player_status == "PLAYING") {
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

    if (auto_manual == 'manual') {
      // select_cast was initiated by clicking a cast in the UI. Its elapsed time will be stale, so get an update from the back-end (CCA) or the mp3_player (browser)
      if (device.uuid == 'browser') {
        setup_playbar($scope.browser_device)
      } else {
        Device.select_cast(device.uuid, function(response) {
          setup_playbar(response.data)
        })
      }
    } else {
      // select_cast was initiated by receiving websocket update. Info should be the very latest
      setup_playbar(device);
    }

    localStorage.setItem('cast_uuid', device.uuid);
  }

  /*
   * User clicked one of the 'modes' in the leftmost column: Presets, Music, Radio etc
   */
  $scope.select_mode = function(mode) {
    //console.log("mode", mode)
    localStorage.setItem('mode', mode);

    $scope.home.mode_ui = mode;

    $scope.home.mp3s = [];

    if (mode == 'presets') {
      Preset.get_all(function(response) {
        $scope.home.presets = response.data;
        if ($scope.home.presets.length == 0) {
          $.notify("No presets found. Try playing some audio and click", "warn")
        }
      })
    }
    // White noise mode is essentially a single directory, as opposed to mult-level like music/spokens
    if (mode == 'white-noise') {
      Mp3.index('white-noise', -1, function(response) {
        if (response.data.length == 0) {
          $.notify("No mp3s found in this folder. You may need to populate and/or refresh your media.", "warn")
        }
        $scope.home.mp3s = response.data
        $scope.safeApply()
      })
    }
    // These modes share a multi-level directory structure
    if (mode == 'music' || mode == 'spoken') {
      Mp3.get_folders(mode, -1, function(response) {
        $scope.safeApply();
        $scope.home.folders = response.data;
        if (response.data.length == 0) {  // No folders...
          Mp3.index(mode, -1, function(response) { // ...and no mp3s
            if (response.data.length == 0) {
              $.notify("No mp3s found. You may need to populate and/or refresh your media.", "warn")
            }
          })
        }
        /*
        Mp3.index(mode, -1, function(response) {
          $scope.home.mp3s = response.data
          $scope.safeApply()
        })
        */

        var folder_id = localStorage.getItem('folder::' + mode)
        if (folder_id > 0) {
          $scope.select_folder(folder_id);
        } else {
          $scope.select_folder(-1);
        }
      })
    }
    if (mode == 'radio') {
      Mp3.get_radio(function(response) {
        $scope.home.radio_stations = response.data;
        if ($scope.home.radio_stations.length == 0) {
          $.notify("No radio stations found. Please configure public/audio/radio.json", "warn")
        }
        console.log(response)
      })
    }
  }

  /*
   * In music/spoken mode, user clicked a folder name or 'Back' in #selector1
   *
   * Alternatively, called by select_mode to select the most recently-selected folder
   */
  $scope.select_folder = function(folder_id) {
    localStorage.setItem('folder::' + $scope.home.mode_ui, folder_id);

    if (folder_id == -1) {
      $scope.home.folder = {
        id: -1
      };
    } else {
      for (var i = 0; i < $scope.home.folders.length; i++) {
        var fol = $scope.home.folders[i];
        if (fol.id == folder_id) {
          $scope.home.folder = fol;
        }
      }
    }

    Mp3.index($scope.home.mode_ui, folder_id, function(response) {
      if (response.data.length > 0) {
        $scope.home.mp3s = response.data
        //$scope.playbar.init($scope.home.mp3s)
      } else {
        $scope.home.mp3s = []
      }
    })
  }

  var title_sort_num = -1;
  $scope.set_mp3_sort = function(sort) {
    var field = "";

    function compare_asc(a,b) {
      if (a[field] < b[field])
        return -1;
      if (a[field] > b[field])
        return 1;
      return 0;
    }

    function compare_desc(a,b) {
      if (a[field] > b[field])
        return -1;
      if (a[field] < b[field])
        return 1;
      return 0;
    }

    // Step 1: appropriately sort $scope.home.mp3s

    $scope.home.mp3_sort_filename = false
    if (sort == 'title') {
      title_sort_num += 1
      if (title_sort_num > 3) { title_sort_num = 0; }
      var title_sort = [ 'title', '-title', 'filename', '-filename' ]
      $scope.home.mp3_sort = title_sort[title_sort_num]
      if (title_sort_num >= 2) {
        $scope.home.mp3_sort_filename = true
      }
    } else {
      title_sort_num = -1
      if ($scope.home.mp3_sort == sort) {
        $scope.home.mp3_sort = "-" + sort
      } else {
        $scope.home.mp3_sort = sort
      }
    }

    field = $scope.home.mp3_sort;
    if (field.match(/^-/)) {
      field = field.replace(/^-/, "")
      console.log("field desc", field)
      $scope.home.mp3s = $scope.home.mp3s.sort(compare_desc);
    } else {
      console.log("field asc", field)
      $scope.home.mp3s = $scope.home.mp3s.sort(compare_asc);
    }

    // Step 2: UPDATE PLAYLIST
    if ($scope.home.device_selected.uuid == 'browser') {
      var playa = $scope.player_mp3;
      var ind = playa.playlist_index;
      var pl = playa.playlist;
      // Nothing to do for empty playlist...we haven't clicked Play yet.
      if (pl.length == 0) { return; }
      console.log("po", playa.playlist_order, "ind", ind)
      var entry = pl[playa.playlist_order[ind]];
      console.log("entry", entry)
      var cur_entry_id = entry['id']

      var mp3s = $scope.home.mp3s;
      var indexCurrentlyPlaying = 0;
      for (var i = 0; i < mp3s.length; i++) {
        var mp3 = mp3s[i];
        if (mp3['id'] == cur_entry_id) {
          indexCurrentlyPlaying = i
          console.log("indexCurrentlyPlaying", indexCurrentlyPlaying)
        }
      }
      // mp3s have been rearranged, now time to update the playlist for the player, whether the browser or a CCA
      var hsh = get_state_local();
      data = {
        state_local: hsh,
        playlist: $scope.get_playlist_from_mp3s(),
        playlist_index: indexCurrentlyPlaying
      };

      // For playing in the browser it's easy, just start playing with a hidden jPlayer and update the playbar
      playa.update_playlist(data)

      $scope.browser_device.state_local = hsh;
    } else {
      // For chromecasts, we have to tell the back-end to load and play the playlist on the given device
      // We then depend on Device.broadcast() to fire when buffering/playing starts. See the init() and $scope.select_cast() functions
      Mp3.play(data, function(response) {
        $scope.buffering = false;
      })
    }


  }

  $scope.current_subfolders = function(folder) {
    return folder && folder.parent_folder_id == $scope.home.folder.id && $scope.home.mode_ui != 'white-noise'
  }

  /*
   * The UI state when a user clicked an MP3 to play it.
   * 
   * This gets attached to the device (see mp3s_controller.rb#play) so that cast's background thread knows how to repeat etc.
   * It is also broadcast to all other users via websockets (see device.rb#broadcast), to be used by the front-end UI for showing play buttons on the appropriate cast/mode/folder/mp3 entry
   */
  function get_state_local() {
    if (!$scope.home.device_selected) {
      console.log("nope")
      return {};
    }
    return {
      cast_uuid: $scope.home.device_selected.uuid,
      mode: $scope.home.mode_ui,
      repeat: $scope.home.device_selected.state_local.repeat,
      shuffle: $scope.home.device_selected.state_local.shuffle,
      folder: ($scope.home.folder ? $scope.home.folder : { id: -1 }),
      mp3: $scope.home.device_selected.state_local.mp3
    }
  }

  // Sort has changed, or play has been clicked
  // Notify player_mp3 or device.rb that the play order has been changed
  $scope.get_playlist_from_mp3s = function() {
    //console.log("play", index)
    public_prefix = dirname(audio_dir)
    url_prefix = window.http_address

    //var regex = new RegExp(RegExp.escape(public_prefix));

    // Creates playlist of mp3 ids+urls by iterating through $scope.home.mp3s -- these can be in any order due to sorting
    var playlist = []
    var mp3s = $scope.home.mp3s;

    function add_playlist(mp3) {
      url = url_prefix + mp3['url']  // We add hostname here rather than the DB because the user could be hitting the server from localhost, 127.0.0.1, IP or a DDNS hostname

      playlist.push({
        id: mp3.id,
        url: url
      });
    }
    for (var i = 0; i < mp3s.length; i++) {
      add_playlist(mp3s[i])
    }
    return playlist
  }

  /*
   * The user has clicked an MP3 in #selector2, in music/spoken/white-noise mode.
   * Construct a playlist of mp3 ids/urls and send it and the user's current UI state to mp3s_controller.rb#play
   */
  $scope.play = function(indexClicked, seekSecs) {

    //$scope.playbar.pause()
    $scope.buffering = true;

    if ($scope.home.mode_ui != "spoken" && $scope.home.mode_ui != "music") {
      $scope.home.folder = null
      $scope.home.folders = []
    }

    var hsh = get_state_local();
    hsh['seek'] = seekSecs;
    data = {
      state_local: hsh,
      playlist: $scope.get_playlist_from_mp3s(),
      playlist_index: indexClicked,
      seek: seekSecs
    };

    if ($scope.home.device_selected.uuid == 'browser') {
      $scope.browser_device.state_local = hsh;
      //$scope.browser_device.mode = $scope.home.mode_ui
      $scope.volume_change($scope.browser_device)

      // For playing in the browser it's easy, just start playing with a hidden jPlayer and update the playbar
      $scope.player_mp3.play_playlist(data)
    } else {
      // For chromecasts, we have to tell the back-end to load and play the playlist on the given device
      // We then depend on Device.broadcast() to fire when buffering/playing starts. See the init() and $scope.select_cast() functions
      Mp3.play(data, function(response) {
        $scope.buffering = false;
      })
    }
  }

  $scope.play_bookmark = function(bookmark) {
    Mp3.get_folder('spoken', $scope.home.folder.id, function(response) {
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

  window.addEventListener('beforeunload', logData, false);

  function logData() {
    if ($scope.home.mode_ui == 'spoken' && $scope.home.device_selected.player_status == "PLAYING") {
      if ($scope.home.device_selected.uuid == 'browser') {
        var mp3_id = $scope.browser_device.state_local.mp3.id;
      } else {
        var mp3_id = $scope.home.device_selected.state_local.mp3.id;
      }
      var elapsed = parseInt($scope.playbar.progress / 1000);
      var url = "/api/mp3s/save_bookmark/" + mp3_id + "/" + elapsed;

      console.log("Trying...")

      $.ajax({
        type: "GET",
        url: url,
        success: function() { console.log("Done!") },
        async: false
      });
    }
  }

  /*
   * The user has clicked a radio station in #selector2 in radio mode.
   * Construct a playlist of that station's mp3 url and send it and the user's current UI state to mp3s_controller.rb#play
   */
  $scope.play_radio = function(station) {
    $scope.home.mode_ui = 'radio'
    $scope.home.radio_station = station
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
    if ($scope.home.device_selected.uuid == 'browser') {
      console.log("station", station)
      $scope.browser_device.state_local = sl;
      $scope.volume_change($scope.browser_device)
      // For playing in the browser it's easy, just start playing with a hidden jPlayer and update the playbar
      $scope.player_mp3.play_playlist(data)
    } else {
      Mp3.play(data, function(response) {
        $scope.buffering = false;
      })    
    }
  }

  $scope.stop_all = function() {
    $.notify("Stopping all chromecasts!", "warn")
    $scope.player_mp3.stop()
    Mp3.stop_all(function(response) {
      $scope.playbar.stop();
    })
  }

  var volume_timer;

  $scope.volume_change = function(device) {
    if (!device) {
      return;
    }
    if (device.uuid == 'browser') {
      $('#jquery_jplayer_1').jPlayer("volume", device.volume_level)
      return;
    }
    clearTimeout(volume_timer);
    volume_timer = setTimeout(function() {  // Timeout prevents user from changing volume 10 times a second
      var val = device.volume_level;
      if (device.volume_level == 1) { val = "1.0" }
      if (device.volume_level == 0) { val = "0.0" }
      Device.volume_change(device.uuid, val, function() {
        //console.log("yay")
      })
    }, 100)
  }

  // Determine if a given mode/folder/mp3 is being played. Works by checking device.state_local[fieldname] against 'val'.
  // This is used to show the play buttons throughout the GUI
  $scope.is_playing = function(type, val) {
    var devices = $scope.home.devices;

    //console.log("$scope.browser_device.state_local[type]", $scope.browser_device.state_local[type], "type", type, "val", val)

    if ($scope.browser_device.player_status == 'PLAYING') {
      var arr = type.split('.');
      var val_device = null;
      if (arr.length == 1) {
        val_device = $scope.browser_device.state_local[arr[0]]
      } else if (arr.length == 2) {
        //console.log("arr", arr, "sl", $scope.browser_device.state_local)
        if ($scope.browser_device.state_local[arr[0]]) {
          val_device = $scope.browser_device.state_local[arr[0]][arr[1]]
        } else {
          console.log("== no statelocal")
        }
      }
      //console.log("val_device", val_device)

      if (val_device == val) {
        return $scope.browser_device;
      }
    }
    for (var i = 0; i < devices.length; i++) {
      var dev = devices[i];
      if (dev.player_status && dev.player_status != "IDLE" && dev.player_status != "UNKNOWN") {
        //console.log("status", dev.player_status, "dev.state_local[type]", dev.state_local[type], "type", type, "val", val)

        var arr = type.split('.');
        if (arr.length == 1) {
          var val_device = dev.state_local[arr[0]]
        } else if (arr.length == 2) {
          //console.log("arr", JSON.stringify(arr), "sl", JSON.stringify(dev.state_local))
          if (dev.state_local[arr[0]]) {
            var val_device = dev.state_local[arr[0]][arr[1]]
          } else {
            console.warn("Could not find dev.state_local[" + arr[0] + "]")
          }
        }

        if (val_device == val) {
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
    if ($scope.home.sync_data.refreshing) {
      $.notify("Please wait until the previous sync is complete", "error")
      return
    }
    $.notify("Beginning sync. This can take several minutes depending on how many new MP3s are found.", "error")

    Mp3.refresh($scope.home.mode_ui, function(response) {

      //console.log("response", response.data)
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

      $scope.select_mode($scope.home.mode_ui);
    }, function() {

    })
  }

  $scope.refresh_devices = function() {
    Device.refresh(function(response) {
      $scope.home.devices = response.data;
      /*
      if (response.data.length == 0) {
        $.notify("No chromecast audio devices or groups found!", "error")
      }
      */
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

