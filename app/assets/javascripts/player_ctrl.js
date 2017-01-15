var init_player = function($scope, $rootScope) {

  $scope.player = {
    interval: null,
    total: 0,
    progress: 0,
    playing: false
  };

  $scope.player.pause = function() {
    $scope.player.playing = false;
    isPaused = true;
  }

  $scope.player.resume = function() {
    $scope.player.playing = true;
    isPaused = false;
  }

  $scope.player.reset = function(lenMs, elapsedMs) {
    console.log("lenms", lenMs, "elapsedMs", elapsedMs)
    $scope.player.total = lenMs;
    $scope.player.progress = elapsedMs;

    $('#time-passed span').text(msToMinSec(elapsedMs));
    $('#playback-duration span').text(msToMinSec(lenMs));    
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

        $('#progress-bar').css('width', Math.ceil(($scope.player.progress / $scope.player.total) * 100) + "%");

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
};
