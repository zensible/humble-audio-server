
multiroomApp.controller('GlobalCtrl', function ($scope, $routeParams, $route, $http, $rootScope) {

  $scope.safeApply = function() {
    if(!$scope.$$phase) {
      $scope.$digest();
    }
  }

  $rootScope.showDefaultError = function(response) {
    var data = response.data;
    var status = response.status;
    console.log("data", data, "status", status)
    if (status === 500) {  // Rails exception occured. Show a friendly message rather than the enormous html/css error coming back from Rails.
      data = "A server error occured. Please try again in a few minutes.";
    }
    var message = "";
    if (typeof data === 'string') {
      message = data;
    } else if (Array.isArray(data)) {
      jQuery.each(data, function(i, val) {
        message += (message === "" ? "" : "<br>") + val;
      });
    } else {
      jQuery.each(data, function(i, val) {
        message += (message === "" ? "" : "<br>") + i + " ";

        // Fixing a bug with messaging where "Status error 5" was showing up. This was likely because
        // of the val[0] that previously existed. As the error message structure types is not consistent
        // it could be that val was sometimes an array, in which case val[0] makes sense. So just in case
        // there is a check for array type, but otherwise val.
        if(Array.isArray(val)) {
          message += val[0]; // ??? path...
        } else {
          message += val; // Usual path...
        }
      });
    }
    $.notify("Error: " + message);
  };

  // Extend RegExp to add an 'escape for regex' function
  RegExp.escape = function( value ) {
    return value.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
  }

});

