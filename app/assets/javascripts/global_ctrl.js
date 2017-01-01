
multiroomApp.controller('GlobalCtrl', function ($scope, $routeParams, $route, $rootScope) {

  $scope.safeApply = function() {
    if(!$scope.$$phase) {
      $scope.$digest();
    }
  }

  /*
   *   Intialize code
   */
  setTimeout(function() {
    $('#top').css('height', ($(window).height()+"px"))
  }, 1)
  //init_player($scope, Ode, $location, $rootScope);

});

