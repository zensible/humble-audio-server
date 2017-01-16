angular.module("multiroomApp").factory('Device', function($rootScope, HttpErrorWrapper) {
  return {

    get_all: function(success, error) {
      HttpErrorWrapper.get("/api/devices/get", success, error);
    },

    refresh: function(success, error) {
      HttpErrorWrapper.get("/api/devices/refresh", success, error);
    },

    volume_change: function(uuid, volume_level, success, error) {
      HttpErrorWrapper.get("/api/devices/volume_change/" + uuid + "/" + volume_level, success, error);
    },

    shuffle_change: function(uuid, shuffle, success, error) {
      HttpErrorWrapper.get("/api/devices/shuffle_change/" + uuid + "/" + shuffle, success, error);
    },

    repeat_change: function(uuid, repeat, success, error) {
      HttpErrorWrapper.get("/api/devices/repeat_change/" + uuid + "/" + repeat, success, error);
    },

    select_cast: function(uuid, success, error) {
      HttpErrorWrapper.get("/api/devices/select/" + uuid, success, error);
    }
  };
});
