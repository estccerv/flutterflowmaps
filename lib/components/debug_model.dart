import '/components/debug_logs_widget.dart';
import '/components/tracked_location_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'debug_widget.dart' show DebugWidget;
import 'package:flutter/material.dart';

class DebugModel extends FlutterFlowModel<DebugWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for trackedLocation component.
  late TrackedLocationModel trackedLocationModel;
  // Model for debugLogs component.
  late DebugLogsModel debugLogsModel;

  @override
  void initState(BuildContext context) {
    trackedLocationModel = createModel(context, () => TrackedLocationModel());
    debugLogsModel = createModel(context, () => DebugLogsModel());
  }

  @override
  void dispose() {
    trackedLocationModel.dispose();
    debugLogsModel.dispose();
  }
}
