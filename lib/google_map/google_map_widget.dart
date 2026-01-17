import '/components/active_button_widget.dart';
import '/components/debug_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'google_map_model.dart';
export 'google_map_model.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  static String routeName = 'GoogleMap';
  static String routePath = '/googleMap';

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget>
    with TickerProviderStateMixin {
  late GoogleMapModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GoogleMapModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {});

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));
    animationsMap.addAll({
      'googleMapOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 500.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          BlurEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 125.0.ms,
            begin: Offset(1.0, 1.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
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
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Builder(builder: (context) {
                final _googleMapMarker = FFAppState().trackedLocation;
                return FlutterFlowGoogleMap(
                  controller: _model.googleMapsController,
                  onCameraIdle: (latLng) => _model.googleMapsCenter = latLng,
                  initialLocation: _model.googleMapsCenter ??=
                      currentUserLocationValue!,
                  markers: [
                    if (_googleMapMarker != null)
                      FlutterFlowMarker(
                        _googleMapMarker.serialize(),
                        _googleMapMarker,
                      ),
                  ],
                  markerColor: GoogleMarkerColor.red,
                  mapType: MapType.normal,
                  style: GoogleMapStyle.standard,
                  initialZoom: 17.0,
                  allowInteraction: true,
                  allowZoom: true,
                  showZoomControls: true,
                  showLocation: true,
                  showCompass: true,
                  showMapToolbar: true,
                  showTraffic: false,
                  centerMapOnMarkerTap: false,
                );
              }).animateOnPageLoad(
                  animationsMap['googleMapOnPageLoadAnimation']!),
              PointerInterceptor(
                intercepting: isWeb,
                child: wrapWithModel(
                  model: _model.debugModel,
                  updateCallback: () => safeSetState(() {}),
                  child: DebugWidget(),
                ),
              ),
              Align(
                alignment: AlignmentDirectional(-1.0, 1.0),
                child: PointerInterceptor(
                  intercepting: isWeb,
                  child: wrapWithModel(
                    model: _model.activeButtonModel,
                    updateCallback: () => safeSetState(() {}),
                    child: ActiveButtonWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
