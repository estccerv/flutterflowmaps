const admin = require("firebase-admin/app");
admin.initializeApp();

const userPresenceCloud = require("./user_presence_cloud.js");
exports.userPresenceCloud = userPresenceCloud.userPresenceCloud;
const createDeliveriesNotification = require("./create_deliveries_notification.js");
exports.createDeliveriesNotification =
  createDeliveriesNotification.createDeliveriesNotification;
const getGoogleDirections = require("./get_google_directions.js");
exports.getGoogleDirections = getGoogleDirections.getGoogleDirections;
