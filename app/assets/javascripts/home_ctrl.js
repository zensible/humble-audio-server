
multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope, Device) {

  var autosize = function() {
    $('#top').css('height', ($(window).height()+"px"))
  }
  autosize();

  $(window).resize(function() {
    autosize()
  })

  $scope.selectMode = function(mode) {
    $scope.home.mode = mode
  }

  var cache = {}

  $scope.home = {
    modes: [ 'Presets', 'Radio', 'Music', 'Spoken', 'White Noise' ],
    mode: '',
    devices: [],
    selector1: [],
    selector2: []
  }

  Device.get(function(response) {
    $scope.home.devices = response.data
  })

  $scope.selectMode('Presets')
});

