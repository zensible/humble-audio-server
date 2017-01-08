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

    stop: function(cast_uuid, success, error) {
      HttpErrorWrapper.get("/api/mp3s/stop/" + cast_uuid, success, error);
    },

    pause: function(cast_uuid, success, error) {
      HttpErrorWrapper.get("/api/mp3s/pause/" + cast_uuid, success, error);
    },

    resume: function(cast_uuid, success, error) {
      HttpErrorWrapper.get("/api/mp3s/resume/" + cast_uuid, success, error);
    },

    next: function(cast_uuid, success, error) {
      HttpErrorWrapper.get("/api/mp3s/next/" + cast_uuid, success, error);
    },

    prev: function(cast_uuid, success, error) {
      HttpErrorWrapper.get("/api/mp3s/prev/" + cast_uuid, success, error);
    },

    get_radio: function(success, error) {
      HttpErrorWrapper.get("/audio/radio.json", success, error);
    },

  };
});
