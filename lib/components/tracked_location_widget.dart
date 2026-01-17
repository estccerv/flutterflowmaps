import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'tracked_location_model.dart';
export 'tracked_location_model.dart';

class TrackedLocationWidget extends StatefulWidget {
  const TrackedLocationWidget({super.key});

  @override
  State<TrackedLocationWidget> createState() => _TrackedLocationWidgetState();
}

class _TrackedLocationWidgetState extends State<TrackedLocationWidget> {
  late TrackedLocationModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrackedLocationModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Padding(
      padding: EdgeInsets.all(5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              valueOrDefault<String>(
                FFAppState().trackedLocation?.toString(),
                'location',
              ),
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                fontSize: 12.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                shadows: [
                  Shadow(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    offset: Offset(0.0, 0.0),
                    blurRadius: 1.0,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
