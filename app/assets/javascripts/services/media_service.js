angular.module("multiroomApp").factory('Media', function($rootScope, HttpErrorWrapper) {
  return {

    get: function(mode, id, success, error) {
      HttpErrorWrapper.get("/api/mp3s/get/" + mode + '/' + id, success, error);
    },

    get_folders: function(success, error) {
      HttpErrorWrapper.get("/api/mp3s/get_folders", success, error);
    },

    refresh: function(mode, success, error) {
      HttpErrorWrapper.get("/api/mp3s/refresh/" + mode, success, error);
    },

    play: function(hsh, success, error) {
      HttpErrorWrapper.post("/api/mp3s/play/", hsh, success, error);
    },

    stop: function(success, error) {
      HttpErrorWrapper.get("/api/mp3s/stop/", success, error);
    },

    pause: function(success, error) {
      HttpErrorWrapper.get("/api/mp3s/pause/", success, error);
    },

    resume: function(success, error) {
      HttpErrorWrapper.get("/api/mp3s/resume", success, error);
    }

  };
});