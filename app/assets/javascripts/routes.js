
if (!window.isBot) {
  angular.module('multiroomApp').config(function($routeProvider) {
    return $routeProvider.when('/home', {
      templateUrl: '/template/setup'
    }).otherwise({
      templateUrl: '/template/setup'
    });
  });
  
}
