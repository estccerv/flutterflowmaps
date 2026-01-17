import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'list_model.dart';
export 'list_model.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({
    super.key,
    required this.deliveries,
  });

  final List<DeliveriesRecord>? deliveries;

  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> with TickerProviderStateMixin {
  late ListModel _model;

  LatLng? currentUserLocationValue;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ListModel());

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
    _model.maybeDispose();

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

    return FlutterFlowGoogleMap(
      controller: _model.googleMapsController,
      onCameraIdle: (latLng) =>
          safeSetState(() => _model.googleMapsCenter = latLng),
      initialLocation: _model.googleMapsCenter ??= currentUserLocationValue!,
      markers: (widget.deliveries
                  ?.map((e) => e.originZone.geopoint)
                  .withoutNulls
                  .toList() ??
              [])
          .map(
            (marker) => FlutterFlowMarker(
              marker.serialize(),
              marker,
              () async {
                context.pushNamed(
                  AcceptanceWidget.routeName,
                  queryParameters: {
                    'deliveryRef': serializeParam(
                      widget.deliveries
                          ?.where((e) =>
                              e.originZone.geopoint == _model.googleMapsCenter)
                          .toList()
                          .firstOrNull
                          ?.reference,
                      ParamType.DocumentReference,
                    ),
                  }.withoutNulls,
                );
              },
            ),
          )
          .toList(),
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
      centerMapOnMarkerTap: true,
    ).animateOnPageLoad(animationsMap['googleMapOnPageLoadAnimation']!);
  }
}
