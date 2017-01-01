angular.module("multiroomApp").factory('Device', function($rootScope, HttpErrorWrapper) {
  return {

    get: function(success, error) {
      HttpErrorWrapper.get("/api/get_devices", success, error);
    },

    refresh: function(success, error) {
      HttpErrorWrapper.get("/api/refresh_devices", success, error);
    }
  };
});
