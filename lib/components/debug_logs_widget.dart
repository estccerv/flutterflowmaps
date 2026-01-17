import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'debug_logs_model.dart';
export 'debug_logs_model.dart';

class DebugLogsWidget extends StatefulWidget {
  const DebugLogsWidget({super.key});

  @override
  State<DebugLogsWidget> createState() => _DebugLogsWidgetState();
}

class _DebugLogsWidgetState extends State<DebugLogsWidget> {
  late DebugLogsModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DebugLogsModel());

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
      child: Builder(
        builder: (context) {
          final debug = FFAppState().debug.toList();

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(debug.length, (debugIndex) {
                final debugItem = debug[debugIndex];
                return Flexible(
                  child: SelectionArea(
                      child: Text(
                    debugItem,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      shadows: [
                        Shadow(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          offset: Offset(0.0, 0.0),
                          blurRadius: 2.0,
                        )
                      ],
                    ),
                  )),
                );
              }).divide(SizedBox(height: 2.0)),
            ),
          );
        },
      ),
    );
  }
}
