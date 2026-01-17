import '/components/active_button_widget.dart';
import '/components/debug_widget.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_static_map.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:mapbox_search/mapbox_search.dart' as mapbox;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'static_map_model.dart';
export 'static_map_model.dart';

class StaticMapWidget extends StatefulWidget {
  const StaticMapWidget({super.key});

  static String routeName = 'StaticMap';
  static String routePath = '/staticMap';

  @override
  State<StaticMapWidget> createState() => _StaticMapWidgetState();
}

class _StaticMapWidgetState extends State<StaticMapWidget>
    with TickerProviderStateMixin {
  late StaticMapModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StaticMapModel());

    animationsMap.addAll({
      'staticMapOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
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
              FlutterFlowStaticMap(
                location: FFAppState().trackedLocation!,
                apiKey: FFDevEnvironmentValues().mapBoxKey,
                style: mapbox.MapBoxStyle.Outdoors,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0.0),
                  bottomRight: Radius.circular(0.0),
                  topLeft: Radius.circular(0.0),
                  topRight: Radius.circular(0.0),
                ),
                markerColor: FlutterFlowTheme.of(context).error,
                cached: true,
                zoom: 17,
                tilt: 0,
                rotation: 0,
              ).animateOnPageLoad(
                  animationsMap['staticMapOnPageLoadAnimation']!),
              wrapWithModel(
                model: _model.debugModel,
                updateCallback: () => safeSetState(() {}),
                child: DebugWidget(),
              ),
              Align(
                alignment: AlignmentDirectional(-1.0, 1.0),
                child: wrapWithModel(
                  model: _model.activeButtonModel,
                  updateCallback: () => safeSetState(() {}),
                  child: ActiveButtonWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
