var init_playbar = function($scope, $rootScope, Media, Device) {

  $scope.playbar = {
    interval: null,
    total: 0,
    progress: 0,
    playing: false
  };

  $scope.playbar.reset = function(lenMs, elapsedMs) {
    //console.log("lenms", lenMs, "elapsedMs", elapsedMs)
    $scope.playbar.total = lenMs;
    $scope.playbar.progress = elapsedMs;

    $('#time-passed span').text(msToMinSec(elapsedMs));
    $('#playback-duration span').text(msToMinSec(lenMs));    
    $('#progress-bar').css('width', '0px');
    clearInterval($scope.playbar.interval);
  }

  var isPaused = false;

  $scope.playbar.play = function() {

    isPaused = false;

    $scope.playbar.playing = true;
    $scope.safeApply();

    $scope.playbar.initPlayProgress();
  }

  function msToMinSec(ms) {
    var min = (ms/1000/60) << 0;
    var sec = Math.floor((ms/1000) % 60);
    if (sec < 10) { sec = '0' + sec }
    return min + ':' + sec;
  }

  $scope.playbar.initPlayProgress = function() {
    var updateMs = 100;
    clearInterval($scope.playbar.interval);
    $scope.playbar.interval = setInterval(function() {
      if (!isPaused) {  // When paused, interval will still run but take no action
        $scope.playbar.progress += updateMs;

        $('#time-passed span').text(msToMinSec($scope.playbar.progress));

        $('#progress-bar').css('width', (parseFloat($scope.playbar.progress) / parseFloat($scope.playbar.total) * 100.0) + "%");

        if ($scope.playbar.progress >= $scope.playbar.total) {
          $('#progress-bar').css('width', '0px');
          clearInterval($scope.playbar.interval);
        }
      }
    }, updateMs);
  }

  $scope.playbar.stop = function() {
    if ($scope.playbar.playing == false) return
    clearInterval($scope.playbar.interval);

    isPaused = true;
    $scope.playbar.playing = false;
    $scope.safeApply();
  }


  /*
   * Go back one entry in the playlist
   */
  $scope.prev = function() {
    if ($scope.home.device.uuid == 'browser') {
      $scope.player_mp3.prev();
    } else {
      Media.prev($scope.home.device.uuid)
    }
  }

  /*
   * Go forward one entry in the playlist
   */
  $scope.next = function() {
    if ($scope.home.device.uuid == 'browser') {
      $scope.player_mp3.next();
    } else {
      Media.next($scope.home.device.uuid)
    }
  }

  $scope.toggleRepeat = function() {
    switch ($scope.home.device.state_local.repeat) {
      case "off":
        $scope.home.device.state_local.repeat = "all";
        break;
      case "all":
        $scope.home.device.state_local.repeat = "one";
        break;
      case "one":
        $scope.home.device.state_local.repeat = "off";
        break;
    }
    var dev = $scope.home.device;

    if ($scope.home.device.uuid != 'browser') {
      Device.repeat_change(dev.uuid, $scope.home.device.state_local.repeat, function() {
        console.log("Repeat change successful")
      })
    }
  }


  $scope.toggleShuffle = function() {
    if ($scope.home.device.state_local.shuffle == "on") {
      $scope.home.device.state_local.shuffle = "off";
    } else {
      $scope.home.device.state_local.shuffle = "on";
    }
    var dev = $scope.home.device;

    if ($scope.home.device.uuid == 'browser') {
      if ($scope.home.device.state_local.shuffle == "on") {
        $scope.player_mp3.shuffle_playlist();
      } else {
        $scope.player_mp3.unshuffle_playlist();
      }
    } else {
      Device.shuffle_change(dev.uuid, $scope.home.device.state_local.shuffle, function() {
        console.log("Shuffle change successful")
      })
    }
  }

  /*
  $scope.stop = function() {
    Media.stop($scope.home.device.uuid)
  }
  */

  $scope.pause = function() {
    if ($scope.home.device.uuid == 'browser') {
      $scope.player_mp3.pause();

      Media.save_bookmark($scope.browser_device.state_local.mp3_id, parseInt($scope.playbar.progress / 1000), function(response) {
      })
    } else {
      Media.pause($scope.home.device.uuid, function(response) {
        $scope.playbar.pause()
      })
    }
  }

  $scope.resume = function() {
    if ($scope.home.device.uuid == 'browser') {
      $scope.player_mp3.resume();
    } else {
      Media.resume($scope.home.device.uuid, function(response) {
        $scope.playbar.resume()
      })
    }
  }

  $scope.playbar.pause = function() {
    $scope.playbar.playing = false;
    isPaused = true;
  }

  $scope.playbar.resume = function() {
    $scope.playbar.playing = true;
    isPaused = false;
  }

  $scope.seek = function(evt) {
    console.log("evt", evt)
    var offsetX = evt.offsetX;
    var tot = $scope.playbar.total;
    var maxWid = $('#progress-wrapper').width();
    var mult = offsetX / maxWid;
    var seekMs = mult * tot;
    var seekSecs = parseInt(seekMs / 1000);
console.log("seekSecs", seekSecs)
    if ($scope.home.device.uuid == 'browser') {
      $scope.player_mp3.seek(seekSecs);
    } else {
      Media.seek($scope.home.device.uuid, seekSecs, function() {

      });
    }
  }


};
