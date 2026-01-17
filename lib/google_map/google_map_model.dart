import '/components/active_button_widget.dart';
import '/components/debug_widget.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'google_map_widget.dart' show GoogleMapWidget;
import 'package:flutter/material.dart';

class GoogleMapModel extends FlutterFlowModel<GoogleMapWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for GoogleMap widget.
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();
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
