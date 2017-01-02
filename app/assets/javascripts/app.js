
var multiroomApp = angular.module('multiroomApp', ['ngResource', 'ngRoute']);

// Add titlecase filter
multiroomApp.filter('secondsToDateTime', [function() {
    return function(seconds) {
        return new Date(1970, 0, 1).setSeconds(seconds);
    };
}])