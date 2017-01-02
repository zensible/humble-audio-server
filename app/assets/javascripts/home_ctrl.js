
multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device, Media) {

  var autosize = function() {
    $('#top').css('height', ($(window).height()+"px"))
  }
  autosize();

  $(window).resize(function() {
    autosize()
  })

  RegExp.escape = function( value ) {
    return value.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
  }

  $scope.selectMode = function(mode) {
    $scope.home.mode = mode
    Media.get(mode, function(response) {
      if (response.data.length == 0) {
        Media.refresh(mode, function(response) {
          console.log(response)
          var stats = response.data['stats']
          console.log("stats", stats)
          Media.get(mode, function(response) {
            $scope.home.media = response.data
          })
        })
      } else {
        $scope.home.media = response.data
      }
    })
  }

  $scope.play = function(mp3) {
    public_prefix = '/Users/eightfold/multiroom/public'
    url_prefix = 'http://192.168.0.103:3000'

    var regex = new RegExp(RegExp.escape(public_prefix));

    var path = mp3['path'];
    url = url_prefix + encodeURI(path.replace(regex, ''))
    url = url.replace(/'/, '%27')

    Media.play({
      id: mp3['id'],
      url: url
    }, function(response) {
      // Show progress bar
      console.log("resp", response)
      console.log("playing!")
    })
  }

  $scope.stop = function() {
    Media.stop()
  }

  $scope.pause = function() {
    Media.pause()
  }

  $scope.refresh_media = function() {
    Media.refresh($scope.home.mode, function() {
      Media.get($scope.home.mode, function(response) {
        $scope.home.media = response.data
      })
    })
  }

  $scope.select_cast = function(device) {
    Media.select_cast(device.friendly_name)    
  }

  var cache = {}

  $scope.home = {
    modes: [ 'presets', 'radio', 'music', 'spoken', 'white noise' ],
    mode: '',
    devices: [],
    selector1: [],
    selector2: [],
    media: []
  }

  Device.get(function(response) {
    $scope.home.devices = response.data
  })

  $scope.selectMode('white-noise')
});

