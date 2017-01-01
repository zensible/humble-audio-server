
multiroomApp.controller('GlobalCtrl', function ($scope, $routeParams, $route, $rootScope) {

  $scope.safeApply = function() {
    if(!$scope.$$phase) {
      $scope.$digest();
    }
  }

  /*
   *   Intialize code
   */

  //init_player($scope, Ode, $location, $rootScope);

});

