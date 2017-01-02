angular.module("multiroomApp").factory('Media', function($rootScope, HttpErrorWrapper) {
  return {

    get: function(mode, success, error) {
      HttpErrorWrapper.get("/api/get_media/" + mode, success, error);
    },

    refresh: function(mode, success, error) {
      HttpErrorWrapper.get("/api/refresh_media/" + mode, success, error);
    },

    play: function(hsh, success, error) {
      HttpErrorWrapper.post("/api/play_media/", hsh, success, error);
    },

    stop: function(success, error) {
      HttpErrorWrapper.get("/api/stop_media/", success, error);
    },

    pause: function(success, error) {
      HttpErrorWrapper.get("/api/pause_media/", success, error);
    },

    select_cast: function(friendly_name, success, error) {
      HttpErrorWrapper.get("/api/select_cast/" + friendly_name, success, error);
    }
  };
});
