var init_mp3_player = function($scope, $rootScope, Media, Device) {

  $scope.player_mp3 = {
    playing: {},
    jplayer: null,
    playlist: [],
    playlist_index: 0
  };

  /*
  var player = MIDI.Player;
  if (window.env == 'test') {
    player.loadFile = function(data, callbackSuccess, callbackProgress, callbackError) {
      player.data = [[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"keySignature","key":0,"scale":0},"track":0},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"timeSignature","numerator":3,"denominator":8,"metronome":24,"thirtyseconds":8},"track":0},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"smpteOffset","frameRate":25,"hour":1,"min":0,"sec":0,"frame":0,"subframe":0},"track":0},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"setTempo","microsecondsPerBeat":1000000},"track":0},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"endOfTrack"},"track":0},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"trackName","text":"Piano right"},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"instrumentName","text":"Steinway Grand Piano"},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"text","text":"bdca426d104a26ac9dcb070447587523"},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":0,"type":"channel","subtype":"programChange","programNumber":0},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":0,"type":"channel","subtype":"controller","controllerType":7,"value":100},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":0,"type":"channel","subtype":"controller","controllerType":91,"value":127},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"endOfTrack"},"track":1},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"trackName","text":"Piano left"},"track":2},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"instrumentName","text":"Steinway Grand Piano"},"track":2},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":1,"type":"channel","subtype":"programChange","programNumber":0},"track":2},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":1,"type":"channel","subtype":"controller","controllerType":7,"value":100},"track":2},0],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":1,"type":"channel","noteNumber":45,"velocity":37,"subtype":"noteOn"},"track":2},0],[{"ticksToEvent":120,"event":{"deltaTime":120,"channel":1,"type":"channel","noteNumber":45,"velocity":0,"subtype":"noteOff"},"track":2},125],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":1,"type":"channel","noteNumber":52,"velocity":33,"subtype":"noteOn"},"track":2},0],[{"ticksToEvent":120,"event":{"deltaTime":120,"channel":1,"type":"channel","noteNumber":52,"velocity":0,"subtype":"noteOff"},"track":2},125],[{"ticksToEvent":0,"event":{"deltaTime":0,"channel":1,"type":"channel","noteNumber":57,"velocity":33,"subtype":"noteOn"},"track":2},0],[{"ticksToEvent":120,"event":{"deltaTime":120,"channel":1,"type":"channel","noteNumber":57,"velocity":0,"subtype":"noteOff"},"track":2},125],[{"ticksToEvent":0,"event":{"deltaTime":0,"type":"meta","subtype":"endOfTrack"},"track":2},0]]
      callbackSuccess()
    }
  }
  */

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

  $scope.player_mp3.play_playlist = function(data) {
    $scope.player_mp3.playlist = data.data;
    $scope.player_mp3.playlist_index = 0;
    playAtIndex()
  }

  var playAtIndex = function() {
    var ind = $scope.player_mp3.playlist_index;
    var pl = $scope.player_mp3.playlist;

    $scope.player_mp3.load(pl[ind].url, function() {
      $scope.player_mp3.play(pl, playAtIndex);
    })    
  }

  /*
   * Retrieve Audio, then download MIDI file at its url. Extract obj.adjustments.bpm and insts. Load all of its soundfonts.
   */
  $scope.player_mp3.load = function(url, callbackLoaded) {
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
    var jp = $scope.player_mp3.jplayer;
    jp.jPlayer('play', seekMs);    

    jp.unbind($.jPlayer.event.ended);
    jp.bind($.jPlayer.event.ended, function(event) { // Add a listener to report the time play began
      jp.unbind($.jPlayer.event.ended);
      playCallback();
    });
  }

  $scope.player_mp3.stop = function() {
    $scope.player_mp3.jplayer.jPlayer('stop');    

    $scope.safeApply();    
  }

  $scope.player_mp3.pause = function() {
    $scope.player_mp3.jplayer.jPlayer('stop');

    $scope.safeApply();    
  }


  init()
}