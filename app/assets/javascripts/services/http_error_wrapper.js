angular.module("multiroomApp").factory('HttpErrorWrapper', function($rootScope, $http) {
  return {

    get: function(url, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading = true;
      return $http.get(url).then(function(response) {
        $rootScope.loading = false;
        success(response)
      }, function(response) {
        $rootScope.loading = false;
        error(response)
      });
    },

    post: function(url, data, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading = true;
      return $http.post(url, data).then(function(response) {
        $rootScope.loading = false;
        success(response)
      }, function(response) {
        $rootScope.loading = false;
        error(response)
      });
    },

    put: function(url, data, config, success, error) {
      error || (error = $rootScope.showDefaultError);
      $rootScope.loading = true;
      return $http.put(url, data, config).then(function(response) {
        $rootScope.loading = false;
        success(response)
      }, function(response) {
        $rootScope.loading = false;
        error(response)
      });
    },

    "delete": function(url, success, error) {
      error || (error = $rootScope.showDefaultError);
      return $http["delete"](url).then(function(response) {
        $rootScope.loading = false;
        success(response)
      }, function(response) {
        $rootScope.loading = false;
        error(response)
      });
    }
  };
});
