var init_mp3_player = function($scope, $rootScope, Media, Device) {

  $scope.player_mp3 = {
    playing: {},
    jplayer: null,
    playlist: [],
    playlist_index: 0,
    mp3: {}
  };

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
    $scope.player_mp3.playlist = shuffle($scope.player_mp3.playlist)
  }

  $scope.player_mp3.unshuffle_playlist = function() {
    $scope.player_mp3.playlist_orig = $scope.player_mp3.playlist;
  }

  $scope.player_mp3.play_playlist = function(data) {
    console.log('playlist', JSON.stringify(data));
    $scope.player_mp3.playlist = data.playlist;

    if ($scope.home.shuffle == 'on') {
      $scope.player_mp3.playlist_orig = JSON.parse(JSON.stringify(data.playlist));
      var clicked = $scope.player_mp3.playlist.shift()
      $scope.player_mp3.playlist = shuffle($scope.player_mp3.playlist)
      $scope.player_mp3.playlist.unshift(clicked)
    }

    $scope.player_mp3.playlist_index = 0;
    playAtIndex()
  }

  var playAtIndex = function() {
    var ind = $scope.player_mp3.playlist_index;
    var pl = $scope.player_mp3.playlist;
    console.log("index", ind)
    var entry = pl[ind];
    console.log("entry.url", entry.url)
    $scope.player_mp3.load(entry.url, function() {
      console.log("001")
      if (entry.id == -1) {  // Playing a radio stream
        $scope.browser_device.state_local.mp3_id = -1;
        $scope.browser_device.state_local.mp3_url = entry.url;

        $scope.browser_device.player_status = "PLAYING";
        $scope.playbar.reset(0, 0)
        $scope.playbar.play()
        $scope.safeApply()
      } else {
        Media.get_by_id(entry.id, function(response) {
      console.log("002")
          var mp3 = response.data;
          $scope.browser_device.state_local.mp3 = mp3;
          $scope.browser_device.state_local.mp3_id = mp3.id;
          $scope.browser_device.state_local.mp3_url = entry.url;
          $scope.browser_device.state_local.folder_id = $scope.home.folder.id;
          $scope.browser_device.player_status = "PLAYING";
          $scope.playbar.reset(mp3['length_seconds'] * 1000, 0)
          $scope.playbar.play()
          $scope.safeApply()
        })
      }

      $scope.player_mp3.play(pl, function() {
      console.log("003")
        $scope.player_mp3.playlist_index += 1

        if ($scope.home.repeat == "one") {
          $scope.player_mp3.playlist_index = 0
        }
        if ($scope.player_mp3.playlist_index >= $scope.player_mp3.playlist.length) { // Reached the end of the playlist
          if ($scope.home.repeat == "all") {  // Repeat isn't on, just stop playing
            $scope.player_mp3.playlist_index = 0
          } else { 
            // Reset ui in some way?
            return;
          }
        }

        playAtIndex()
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
    jp.unbind($.jPlayer.event.canplay);
    jp.bind($.jPlayer.event.canplay, function(event) { // Add a listener to report the time play began
      jp.unbind($.jPlayer.event.canplay);
      callbackLoaded(jp.data('jPlayer').status.duration);
    });
  }

  $scope.player_mp3.play = function(seekMs, playCallback) {  // midi == MIDI.Player
    if (window.env == 'test') {
      setTimeout(function() {
        playCallback();
      }, 3000)
      return;
    }

    var jp = $scope.player_mp3.jplayer;
    jp.jPlayer('play', seekMs);

    jp.unbind($.jPlayer.event.ended);
    jp.bind($.jPlayer.event.ended, function(event) { // Add a listener to report the time play began
      jp.unbind($.jPlayer.event.ended);
      playCallback();
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
    console.log("$scope.player_mp3.playlist_index", $scope.player_mp3.playlist_index)
    playAtIndex()
  }

  $scope.player_mp3.stop = function() {
    $scope.player_mp3.jplayer.jPlayer('stop');    

    $scope.safeApply();    
  }

  $scope.player_mp3.stop = function() {
    $scope.player_mp3.jplayer.jPlayer('stop');    

    $scope.safeApply();    
  }

  var pausedMs = 0;
  $scope.player_mp3.pause = function() {
    $scope.browser_device.player_status = "PAUSED";

    if (window.env == 'test') {
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