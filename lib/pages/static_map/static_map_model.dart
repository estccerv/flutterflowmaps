import '/components/active_button_widget.dart';
import '/components/debug_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'static_map_widget.dart' show StaticMapWidget;
import 'package:flutter/material.dart';

class StaticMapModel extends FlutterFlowModel<StaticMapWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Debug component.
  late DebugModel debugModel;
  // Model for activeButton component.
  late ActiveButtonModel activeButtonModel;

  @override
  void initState(BuildContext context) {
    debugModel = createModel(context, () => DebugModel());
    activeButtonModel = createModel(context, () => ActiveButtonModel());
  }

  @override
  void dispose() {
    debugModel.dispose();
    activeButtonModel.dispose();
  }
}
