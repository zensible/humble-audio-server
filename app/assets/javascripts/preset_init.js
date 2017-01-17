var init_presets = function($scope, $rootScope, Media, Device, Preset) {

  $scope.preset_create = function() {
    name = window.prompt("Please enter a playlist name", "");
    if (name) {
      Preset.create({ "name": name }, function(response) {
        Preset.get_all(function(response) {
          $scope.home.presets = response.data;
        })
      })
    }
  }

  $scope.play_preset = function(id) {
    Preset.play(id)
  }

};
