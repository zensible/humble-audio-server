
if (!window.isBot) {
  angular.module('multiroomApp').config(function($routeProvider) {
    return $routeProvider.when('/home', {
      templateUrl: '/template/home'
    }).otherwise({
      templateUrl: '/template/home'
    });
  });
  
}
