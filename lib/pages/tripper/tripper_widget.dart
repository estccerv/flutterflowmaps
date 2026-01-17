import '/components/debug_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'tripper_model.dart';
export 'tripper_model.dart';

class TripperWidget extends StatefulWidget {
  const TripperWidget({super.key});

  static String routeName = 'Tripper';
  static String routePath = '/tripper';

  @override
  State<TripperWidget> createState() => _TripperWidgetState();
}

class _TripperWidgetState extends State<TripperWidget> {
  late TripperModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TripperModel());

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserLocationValue == null) {
      return Container(
        color: FlutterFlowTheme.of(context).primaryBackground,
        child: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                child: custom_widgets.RouteTripper(
                  width: double.infinity,
                  height: double.infinity,
                  routeColor: FlutterFlowTheme.of(context).primary,
                  originMarkerColor: FlutterFlowTheme.of(context).warning,
                  destinationMarkerColor: FlutterFlowTheme.of(context).error,
                  getGoogleDirectionsEndpoint:
                      'https://us-central1-map-test-tgdjcg.cloudfunctions.net/getGoogleDirections',
                  googleMapsApiKey: 'AIzaSyCUn1jlf--8oSp-nvF7CP-u0hpqTCchdFA',
                  origin: currentUserLocationValue,
                ),
              ),
              wrapWithModel(
                model: _model.debugModel,
                updateCallback: () => safeSetState(() {}),
                child: DebugWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
