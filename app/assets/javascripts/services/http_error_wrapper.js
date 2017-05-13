angular.module("multiroomApp").factory('HttpErrorWrapper', function($rootScope, $http) {
  return {

    get: function(url, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading += 1;
      return $http.get(url).then(function(response) {
        $rootScope.loading -= 1;
        success(response)
      }, function(response) {
        $rootScope.loading -= 1;
        error(response)
      });
    },

    post: function(url, data, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading += 1;
      return $http.post(url, data).then(function(response) {
        $rootScope.loading -= 1;
        success(response)
      }, function(response) {
        $rootScope.loading -= 1;
        error(response)
      });
    },

    put: function(url, data, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading += 1;
      return $http.put(url, data).then(function(response) {
        $rootScope.loading -= 1;
        success(response)
      }, function(response) {
        $rootScope.loading -= 1;
        error(response)
      });
    },

    "delete": function(url, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading += 1;
      return $http["delete"](url).then(function(response) {
        $rootScope.loading -= 1;
        success(response)
      }, function(response) {
        $rootScope.loading -= 1;
        error(response)
      });
    }
  };
});
