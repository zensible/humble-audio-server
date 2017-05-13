var init_presets = function($scope, $rootScope, Mp3, Device, Preset) {

  function refresh() {
    Preset.get_all(function(response) {
      $scope.home.presets = response.data;
    })
  }

  $scope.preset_create = function() {
    var name = window.prompt("Please enter a playlist name", "");
    if (name) {
      Preset.create({ "name": name }, function(response) {
        refresh();
      })
    }
  }

  $scope.play_preset = function(id) {
    Preset.play(id, function(response) {
      console.log(response)
    })
  }

  $scope.save_preset_schedule = function(hsh) {
    Preset.update(hsh, function(response) {
      refresh();
    })
  }

  $scope.delete_preset = function(id) {
    if (confirm("Are you sure you want to delete this preset?")) {
      Preset.destroy(id, function(response) {
        refresh();
        $.notify("Preset deleted!")
      })
    }
  }

};
