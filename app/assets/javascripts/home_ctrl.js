
multiroomApp.controller('HomeCtrl', function ($scope, $routeParams, $route, $rootScope) {

  var autosize = function() {
    $('#top').css('height', ($(window).height()+"px"))
  }
  autosize();

  $(window).resize(function() {
    autosize()
  })

  $scope.selectMode = function(mode) {
    alert(mode)
  }

  var cache = {}

  $scope.home = {
    modes: [ 'Presets', 'Radio', 'Music', 'Spoken', 'White Noise' ],
    devices: [],
    selector1: [],
    selector2: []
  }
});

