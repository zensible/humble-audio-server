var init_player = function($scope, $rootScope, Media, Device) {

  $scope.player = {
    interval: null,
    total: 0,
    progress: 0,
    playing: false
  };

  $scope.player.reset = function(lenMs, elapsedMs) {
    console.log("lenms", lenMs, "elapsedMs", elapsedMs)
    $scope.player.total = lenMs;
    $scope.player.progress = elapsedMs;

    $('#time-passed span').text(msToMinSec(elapsedMs));
    $('#playback-duration span').text(msToMinSec(lenMs));    
    $('#progress-bar').css('width', '0px');
    clearInterval($scope.player.interval);
  }

  var isPaused = false;

  $scope.player.play = function() {

    isPaused = false;

    $scope.player.playing = true;
    $scope.safeApply();

    $scope.player.initPlayProgress();
  }

  function msToMinSec(ms) {
    var min = (ms/1000/60) << 0;
    var sec = Math.floor((ms/1000) % 60);
    if (sec < 10) { sec = '0' + sec }
    return min + ':' + sec;
  }

  $scope.player.initPlayProgress = function() {
    var updateMs = 100;
    clearInterval($scope.player.interval);
    $scope.player.interval = setInterval(function() {
      if (!isPaused) {  // When paused, interval will still run but take no action
        $scope.player.progress += updateMs;

        $('#time-passed span').text(msToMinSec($scope.player.progress));

        $('#progress-bar').css('width', (parseFloat($scope.player.progress) / parseFloat($scope.player.total) * 100.0) + "%");

        if ($scope.player.progress >= $scope.player.total) {
          $('#progress-bar').css('width', '0px');
          clearInterval($scope.player.interval);
        }
      }
    }, updateMs);
  }

  $scope.player.stop = function() {
    if ($scope.player.playing == false) return
    clearInterval($scope.player.interval);

    isPaused = true;
    $scope.player.playing = false;
    $scope.safeApply();
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
    var dev = $scope.home.device;
    Device.repeat_change(dev.uuid, $scope.home.repeat, function() {
      console.log("Repeat change successful")
    })
  }


  $scope.toggleShuffle = function() {
    if ($scope.home.shuffle == "on") {
      $scope.home.shuffle = "off";
    } else {
      $scope.home.shuffle = "on";
    }
    var dev = $scope.home.device;
    Device.shuffle_change(dev.uuid, $scope.home.shuffle, function() {
      console.log("Shuffle change successful")
    })
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

  $scope.player.pause = function() {
    $scope.player.playing = false;
    isPaused = true;
  }

  $scope.player.resume = function() {
    $scope.player.playing = true;
    isPaused = false;
  }


};
