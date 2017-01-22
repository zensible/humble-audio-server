angular.module("multiroomApp").factory('Preset', function($rootScope, HttpErrorWrapper) {
  return {

    get_all: function(success, error) {
      HttpErrorWrapper.get("/api/presets/get_all", success, error);
    },

    create: function(hsh, success, error) {
      HttpErrorWrapper.post("/api/presets/create", hsh, success, error);
    },

    destroy: function(id, success, error) {
      HttpErrorWrapper.get("/api/presets/destroy/" + id, success, error);
    },

    update: function(hsh, success, error) {
      HttpErrorWrapper.put("/api/presets/update", hsh, success, error);
    },

    play: function(id, success, error) {
      HttpErrorWrapper.get("/api/presets/play/" + id, success, error);
    },

    select_cast: function(uuid, success, error) {
      HttpErrorWrapper.get("/api/devices/select/" + uuid, success, error);
    }
  };
});
