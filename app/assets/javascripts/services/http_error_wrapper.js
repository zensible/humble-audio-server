angular.module("multiroomApp").factory('HttpErrorWrapper', function($rootScope, $http) {
  return {

    get: function(url, success, error) {
      error || (error = $rootScope.showDefaultError);
      return $http.get(url).then(success, error);
    },

    post: function(url, data, success, error) {
      error || (error = $rootScope.showDefaultError);
      return $http.post(url, data).then(success, error);
    },

    put: function(url, data, config, success, error) {
      error || (error = $rootScope.showDefaultError);
      return $http.put(url, data, config).then(success, error);
    },

    "delete": function(url, success, error) {
      error || (error = $rootScope.showDefaultError);
      return $http["delete"](url).then(success, error);
    }
  };
});
