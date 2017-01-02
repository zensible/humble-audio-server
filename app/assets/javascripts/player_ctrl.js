var init_player = function($scope, $rootScope) {

  $scope.player = {
    interval: null,
    total: 0,
    progress: 0,
    playing: false
  };

  $scope.playlist = {
    items: [],
    current_index: null,
    current_item: {}
  }

  $scope.player.allowPlaylist = false;

  $scope.hovered = null;

  $scope.hover = function(index) {
    $scope.hovered = index;
  }

  /*
   * Initialize playlist. Load first item if available.
   */
  $scope.player.init = function(playlist) {
    console.log("playlist", playlist)
    $scope.playlist.items = [];
    if (playlist && playlist.length > 0) {
      $scope.playlist.items = playlist;
      $scope.playlist.current_index = -1;
      $scope.playlist.current_item = $scope.playlist.items[0];
    }
  }

  /*
   * Invoked from song list on home/board, and from the player at the bottom of the screen.
   * Loads and plays given item from the playlist
   *
   * Play given item in the playlist.  Plays from item.position_ms
   *
   */
  $scope.player.play = function(index, posMs, playCallback) {

    isPaused = false;

    $scope.hovered = index;

    $scope.player.playing = true;
    $scope.safeApply();

    if (index === undefined) { index = $scope.playlist.current_index || 0; }

    // Switch to indicated item in the playlist
    var item = $scope.playlist.items[index];
    $scope.playlist.current_index = index;
    $scope.playlist.current_item = item;

    // Always resume from last point the song was paused or switched away from
    if (posMs === undefined) { posMs = $scope.playlist.current_item.position_ms || 0; }
    $scope.playlist.current_item.position_ms = posMs;
    console.log("item", item)

    var len = item.length_seconds;
    $scope.player.reset(len * 1000);
    $scope.player.initPlayProgress();
    //$scope.player_mp3.play(Math.floor(posMs / 1000), $scope.player.nextAuto);
  }

  /*
   * Resets the state of the UI based on song length and item.position_ms
   */
  $scope.player.reset = function(lenMs) {
    var item = $scope.playlist.current_item;
    var startMs = item.position_ms;

    $scope.player.total = lenMs;
    $scope.player.progress = startMs;

    $('#playbackChrono__timePassed span').text(msToMinSec(startMs));
    $('#playbackChrono__duration span').text(msToMinSec(lenMs));
  }

  $scope.player.export = function() {
    $rootScope.$broadcast("composer::export");
    return;
  }

  /*
   * Reset player's progress bar and timePassed every 100ms
   */
  var isPaused = false;

  $scope.player.initPlayProgress = function() {
    var updateMs = 100;
    clearInterval($scope.player.interval);
    $scope.player.interval = setInterval(function() {
      if (!isPaused) {  // When paused, interval will still run but take no action
        $scope.player.progress += updateMs;
        $scope.playlist.current_item.position_ms = $scope.player.progress;

        $('#playbackChrono__timePassed span').text(msToMinSec($scope.player.progress));

        $('#playbackChrono__progressBar').css('width', Math.ceil(($scope.player.progress / $scope.player.total) * 100) + "%");

        if ($scope.player.progress >= $scope.player.total) {

          $('#playbackChrono__progressBar').css('width', '0px');
          clearInterval($scope.player.interval);
        }
      }
    }, updateMs);
  }

  $scope.player.stop = function() {
    if ($scope.player.playing == false) return

    isPaused = true;
    $scope.playlist.current_item.position_ms = 0;
    $scope.player.playing = false;
    $scope.safeApply();
    $scope.ode.stop();
    $scope.player_midi.stop();
    $scope.player_mp3.stop();
  }

  $scope.player.pause = function() {
    $scope.player.playing = false;
    isPaused = true;
  }

  $scope.player.resume = function() {
    $scope.player.playing = true;
    isPaused = false;
  }

  // User clicked the progress bar, seek to that part of the song
  $scope.player.seek = function(evt) {
    //if (!cursorPlay.playing) { return; }
    var offsetX = evt.offsetX;
    var tot = $scope.player.total;
    var maxWid = $('#playbackChrono__progressWrapper').width();
    var mult = offsetX / maxWid;
    var seekMs = mult * tot;

    var item = $scope.playlist.current_item;
    item.position_ms = seekMs;
    $scope.player.reset(tot);

    $scope.player.stop();
    $scope.player.playing = true;
    switch (item.type) {
      case "ode":
        $scope.ode.play(cursorCompile.curSong, seekMs, $scope.player.nextAuto);
        break;
      case "audio":
        if (item.file_extension == '.mid') {
          $scope.midi.play(seekMs, $scope.player.nextAuto);
        }
        if (item.file_extension == '.mp3') {
          $scope.player_mp3.play(Math.floor(seekMs / 1000), $scope.player.nextAuto);
        }
        break;
    }
  }

  $scope.player.nextAuto = function() {
    setTimeout(function() {
      $scope.player.next()
    }, 2000) // Wait 2 seconds before auto-playing next track
  }

  $scope.player.next = function() {
    if ($scope.playlist.current_index < $scope.playlist.items.length - 1) {
      $scope.playlist.current_item.position_ms = 0;
      $scope.player.play($scope.playlist.current_index + 1);
    } else {
      $scope.player.stop();
    }
  }

  $scope.player.prev = function() {
    if ($scope.playlist.current_index > 0) {
      $scope.player.play($scope.playlist.current_index - 1);
    }
  }

  function msToMinSec(ms) {
    var min = (ms/1000/60) << 0;
    var sec = Math.floor((ms/1000) % 60);
    if (sec < 10) { sec = '0' + sec }
    return min + ':' + sec;
  }

  $scope.player.showVol = function() {
    $('.volume').addClass('expanded');
  }

  $scope.player.hideVol = function() {
    $('.volume').removeClass('expanded');
  }

};
