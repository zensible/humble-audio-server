var init_mp3_player = function($scope, $rootScope, Mp3, Device) {

  $scope.player_mp3 = {
    playing: {},
    jplayer: null,
    playlist: [],
    playlist_index: 0,
    playlist_order: [],
    orig_index: -1,
    mp3: {}
  };

  var playa = $scope.player_mp3;

  var init = function() {
    $scope.player_mp3.jplayer = $("#jquery_jplayer_1").jPlayer({
      ready: function () {
        //alert('ready')
      },
      //swfPath: "../../dist/jplayer",
      supplied: "mp3",
      wmode: "window",
      useStateClassSkin: true,
      autoBlur: false,
      smoothPlayBar: true,
      keyEnabled: true,
      remainingDuration: true,
      toggleDuration: true
    });
    
  }

  $scope.player_mp3.shuffle_playlist = function() {

    // Filter out currently playing song
    var cur_index_val = playa.playlist_order[playa.playlist_index]
    playa.playlist_order = _.reject(playa.playlist_order, function(num){ return num == cur_index_val; });

    // Shuffle
    playa.playlist_order = shuffle(playa.playlist_order);
    playa.playlist_order.unshift(cur_index_val)
    playa.playlist_index = 0;
    //playa.playlist_index = playa.playlist_order.indexOf(playa.playlist_index)
  }

  $scope.player_mp3.unshuffle_playlist = function() {
    var cur_index_val = playa.playlist_order[playa.playlist_index]

    playa.playlist_order = playa.playlist_order.sort(function(a, b) { return a - b })
    playa.playlist_index = playa.playlist_order.indexOf(cur_index_val)
  }

  $scope.player_mp3.play_playlist = function(data) {
    //console.log('playlist', JSON.stringify(data));
    // playa: $scope.player_mp3
    playa.orig_index = data.playlist_index;
    playa.playlist = data.playlist;
    playa.playlist_order = [];
    playa.playlist_index = data.playlist_index;
    for (var i = 0; i < data.playlist.length; i++) {
      playa.playlist_order.push(i);
    }

    if ($scope.home.device_selected.state_local.shuffle == 'on') {
      playa.shuffle_playlist();
    }
    //console.log("$scope.player_mp3.playlist_order", playa.playlist_order)

    //$scope.player_mp3.playlist_index = 0;
    playAtIndex(true)
  }

  var playAtIndex = function(is_orig_play) {
    var ind = playa.playlist_index;
    var pl = playa.playlist;
    var entry = pl[playa.playlist_order[ind]];
    //console.log($scope.player_mp3)
    $scope.player_mp3.load(entry.url, function() {
      if (entry.id == -1) {  // Playing a radio stream
        $scope.browser_device.state_local.mp3 = entry;

        $scope.browser_device.player_status = "PLAYING";
        $scope.playbar.reset(0, 0)
        $scope.playbar.play()
        $scope.safeApply()
      } else {
        Mp3.get_by_id(entry.id, function(response) {
          var mp3 = response.data;
          $scope.browser_device.state_local.mp3 = mp3;
          //$scope.browser_device.state_local.mp3_id = mp3.id;
          $scope.browser_device.state_local.mp3.url = entry.url;
          if ($scope.home.folder) {
            $scope.browser_device.state_local.folder = $scope.home.folder;
          }
          $scope.browser_device.player_status = "PLAYING";
          $scope.playbar.reset(mp3['length_seconds'] * 1000, 0)
          $scope.playbar.play()
          $scope.safeApply()
          //console.log($("#song-name").text())
        })
      }

      $scope.player_mp3.play(0, function() {  // Play is complete, advance in the playlist
        $scope.player_mp3.playlist_index += 1

        if ($scope.home.device_selected.state_local.repeat == "one") {
          $scope.player_mp3.playlist_index -= 1;
        } else {
          if (playa.playlist_index >= playa.playlist_order.length) { // Reached the end of the playlist
            playa.playlist_index = 0;
          }

          // We've played the playlist until we're back to the first song clicked
          if (!is_orig_play && playa.playlist_order[playa.playlist_index] == playa.orig_index) {
            if ($scope.home.device_selected.state_local.repeat != "all") {
              // If repeat is 'all', do nothing -- just keep on playin'
              return;  // If it's off, stop here
            }
          }
        }

        playAtIndex(false)
      });
    })    
  }

  /*
   * Retrieve Audio, then download MIDI file at its url. Extract obj.adjustments.bpm and insts. Load all of its soundfonts.
   */

  $scope.player_mp3.load = function(url, callbackLoaded) {
    if (window.env == 'test') {
      callbackLoaded();
      return;
    }

    var jp = $scope.player_mp3.jplayer;
    jp.jPlayer("setMedia", {
      title: "Bubble",
      mp3: url
    });
    jp.unbind($.jPlayer.event.loadeddata);
    jp.bind($.jPlayer.event.canplay, function(event) { // Add a listener to report the time play began
      jp.unbind($.jPlayer.event.canplay);
      callbackLoaded(jp.data('jPlayer').status.duration);
    });
    jp.bind($.jPlayer.event.timeupdate, function(event) {
      $scope.browser_device.state_local.elapsed = event.jPlayer.status.currentTime
    })
  }

  var testTimeout = null;
  $scope.player_mp3.play = function(seekMs, playCallback) {  // midi == MIDI.Player
    if (window.env == 'test') {
      clearTimeout(testTimeout)
      testTimeout = setTimeout(function() {
        playCallback();
      }, 4000)
      return;
    }

    var jp = $scope.player_mp3.jplayer;
    jp.jPlayer('play', seekMs);

    //jp.unbind($.jPlayer.event.ended);
    jp.bind($.jPlayer.event.ended, function(event) { // Add a listener to report the time play began
      jp.unbind($.jPlayer.event.ended);
      playCallback();
    });
    jp.bind($.jPlayer.event.error, function(evt) {
      jp.unbind($.jPlayer.event.error);
      console.log("jplayer err", evt)
    });
  }

  $scope.player_mp3.prev = function() {
    $scope.player_mp3.playlist_index -= 1
    if ($scope.player_mp3.playlist_index < 0) {
      $scope.player_mp3.playlist_index = $scope.player_mp3.playlist.length - 1
    }
    playAtIndex()

    $scope.safeApply();    
  }

  $scope.player_mp3.next = function() {
    $scope.player_mp3.playlist_index += 1
    if ($scope.player_mp3.playlist_index >= $scope.player_mp3.playlist.length) {
      $scope.player_mp3.playlist_index = 0
    }
    playAtIndex()
  }

  $scope.player_mp3.stop = function() {
    if (window.env != 'test') {
      clearTimeout(testTimeout)
      $scope.player_mp3.jplayer.jPlayer('stop');    
    }
    $scope.browser_device.player_status = "STOPPED";

    $scope.safeApply();    
  }

  var pausedMs = 0;
  $scope.player_mp3.pause = function() {
    $scope.browser_device.player_status = "PAUSED";

    if (window.env == 'test') {
      clearTimeout(testTimeout)
      pausedMs == 1000;
    } else {
      $scope.player_mp3.jplayer.jPlayer('stop');
      pausedMs = scope.player_mp3.jplayer.data('jPlayer').status.currentTime;
    }
    $scope.playbar.pause()

    $scope.safeApply();    
  }

  $scope.player_mp3.resume = function() {
    $scope.browser_device.player_status = "PLAYING";

    if (window.env != 'test') {
      $scope.player_mp3.jplayer.jPlayer('play', pausedMs);
    }

    $scope.playbar.resume()

    $scope.safeApply();    
  }

  $scope.player_mp3.seek = function(secs) {
    $scope.browser_device.player_status = "PLAYING";

    if (window.env != 'test') {
      $scope.player_mp3.jplayer.jPlayer('play', secs);
    }
    $scope.playbar.reset($scope.playbar.total, parseInt(secs * 1000))
    $scope.playbar.play()

    $scope.safeApply();    
  }


  init()
}