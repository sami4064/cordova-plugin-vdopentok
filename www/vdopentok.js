/*global cordova, module*/

module.exports = {
    startVideo: function (kApiKey, kSession, kToken, successCallback, errorCallback) {
               cordova.exec(successCallback, errorCallback, "VDOpentok", "startVideo", [kApiKey, kSession, kToken]);
    }
};

