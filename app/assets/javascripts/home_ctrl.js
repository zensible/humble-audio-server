
multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Media) {

  window.scope = $scope;

  var autosize = function() {
    //$('#top').css('height', ($(window).height()+"px"))
  }
  autosize();

  $(window).resize(function() {
    autosize()
  })

  RegExp.escape = function( value ) {
    return value.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
  }

  $scope.getMedia = function(mode, id, callback) {
    Media.get(mode, -1, function(response) {
      /*
      if (response.data.length == 0) {
        Media.refresh(mode, function(response) {
          var stats = response.data['stats']
          Media.get(mode, function(response) {
            $scope.home.media = response.data
          })
        })
      } else {
      */
      $scope.home.media = response.data
      $scope.player.init($scope.home.media)
    })
  }

  $scope.selectMode = function(mode) {
    //if ($scope.home.mode == 'mode') { return; }
    $scope.home.mode = mode

    $scope.home.media = [];

    if (mode == 'white-noise') {
      $scope.getMedia('white-noise', -1, function() {
        console.log("DONE")
      })
    }
    if (mode == 'music') {
      Media.get_folders(function(response) {
        $scope.home.folders = response.data
      })
    }
  }

  $scope.get_media_folder = function(id) {
    Media.get('music', id, function(response) {
      /*
      if (response.data.length == 0) {
        Media.refresh(mode, function(response) {
          var stats = response.data['stats']
          Media.get(mode, function(response) {
            $scope.home.media = response.data
          })
        })
      } else {
      */
      $scope.home.media = response.data
      $scope.player.init($scope.home.media)
    })    
  }

  $scope.play = function(index) {
    //var mp3 = $scope.home.media[index];

    public_prefix = '/Users/eightfold/multiroom/public'
    url_prefix = 'http://192.168.0.103:3000'

    var regex = new RegExp(RegExp.escape(public_prefix));

    var url_playlist = []
    var mp3s = $scope.home.media;
    for (var i = index; i < mp3s.length; i++) {
      var mp3 = mp3s[i];

      var path = mp3['path'];
      url = url_prefix + encodeURI(path.replace(regex, ''))
      url = url.replace(/'/g, '%27')

      url_playlist.push(url);
    }
    for (var i = 0; i < index; i++) {
      var mp3 = mp3s[i];

      var path = mp3['path'];
      url = url_prefix + encodeURI(path.replace(regex, ''))
      url = url.replace(/'/g, '%27')

      url_playlist.push(url);
    }

    $scope.player.pause()
    $scope.buffering = true;

    // Buffering begins...
    var item = $scope.playlist.items[index];
    $scope.playlist.current_index = index;
    $scope.playlist.current_item = item;

    Media.play({ urls: url_playlist }, function(response) {
      $scope.buffering = false;
      // Buffering complete.
      $scope.player.play(index, 0, function() { })
      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })
  }

  $scope.stop = function() {
    Media.stop()
  }

  $scope.pause = function() {
    Media.pause(function(response) {
      $scope.player.pause()
    })
  }

  $scope.resume = function() {
    Media.resume(function(response) {
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
      Device.volume_change(device.friendly_name, val)
    }, 100)
  }

  $scope.basename = function(str)
  {
     var base = new String(str).substring(str.lastIndexOf('/') + 1); 
      if(base.lastIndexOf(".") != -1)       
          base = base.substring(0, base.lastIndexOf("."));
     return base;
  }

  init_player($scope, $rootScope);

  $scope.refresh_media = function() {
    Media.refresh($scope.home.mode, function() {
      $scope.selectMode($scope.home.mode);
    })
  }

  $scope.select_cast = function(device) {
    Device.select_cast(device.friendly_name)    
  }

  var cache = {}

  $scope.home = {
    mode: '',
    devices: [],
    selector1: [],
    selector2: [],
    media: []
  }

  Device.get(function(response) {
    $scope.home.devices = response.data
  })

  $scope.selectMode('music')
});

