import '/components/debug_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'tripper_widget.dart' show TripperWidget;
import 'package:flutter/material.dart';

class TripperModel extends FlutterFlowModel<TripperWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Debug component.
  late DebugModel debugModel;

  @override
  void initState(BuildContext context) {
    debugModel = createModel(context, () => DebugModel());
  }

  @override
  void dispose() {
    debugModel.dispose();
  }
}
