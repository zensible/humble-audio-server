var init_presets = function($scope, $rootScope, Media, Device, Preset) {

  $scope.preset_create = function() {
    var name = window.prompt("Please enter a playlist name", "");
    if (name) {
      Preset.create({ "name": name }, function(response) {
        Preset.get_all(function(response) {
          $scope.home.presets = response.data;
        })
      })
    }
  }

  $scope.play_preset = function(id) {
    Preset.play(id, function(response) {
      console.log(response)
    })
  }

  $scope.save_preset_schedule = function(hsh) {
    Preset.update(hsh)
  }

};
