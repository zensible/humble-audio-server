
var multiroomApp = angular.module('multiroomApp', ['ngResource', 'ngRoute']);

// Add titlecase filter
multiroomApp.filter('secondsToDateTime', [function() {
    return function(seconds) {
        return new Date(1970, 0, 1).setSeconds(seconds);
    };
}])

multiroomApp.filter('modeName', [function() {
    return function(str) {
      str = str.replace(/-/, ' ');
      return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();})
    };
}])