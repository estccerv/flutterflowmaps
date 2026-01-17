import '/backend/custom_cloud_functions/custom_cloud_function_response_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_widget.dart' show BusinessWidget;
import 'package:flutter/material.dart';

class BusinessModel extends FlutterFlowModel<BusinessWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - findNearbyAvailableDrivers] action in Button widget.
  List<String>? drivers;
  // Stores action output result for [Cloud Function - createDeliveriesNotification] action in Button widget.
  CreateDeliveriesNotificationCloudFunctionCallResponse? cloudFunctionNotify;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
