import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'active_button_model.dart';
export 'active_button_model.dart';

class ActiveButtonWidget extends StatefulWidget {
  const ActiveButtonWidget({super.key});

  @override
  State<ActiveButtonWidget> createState() => _ActiveButtonWidgetState();
}

class _ActiveButtonWidgetState extends State<ActiveButtonWidget> {
  late ActiveButtonModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ActiveButtonModel());

    _model.switchValue = FFAppState().track;
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
      padding: EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Switch.adaptive(
              value: _model.switchValue!,
              onChanged: (newValue) async {
                safeSetState(() => _model.switchValue = newValue);
                if (newValue) {
                  FFAppState().track = _model.switchValue!;
                  safeSetState(() {});
                } else {
                  FFAppState().track = _model.switchValue!;
                  safeSetState(() {});
                }
              },
              activeColor: FlutterFlowTheme.of(context).secondaryBackground,
              activeTrackColor: FlutterFlowTheme.of(context).success,
              inactiveTrackColor: FlutterFlowTheme.of(context).error,
              inactiveThumbColor:
                  FlutterFlowTheme.of(context).secondaryBackground,
            ),
          ),
          Text(
            _model.switchValue! ? 'Active' : 'Disable',
            style: FlutterFlowTheme.of(context).titleLarge.override(
              font: GoogleFonts.interTight(
                fontWeight: FlutterFlowTheme.of(context).titleLarge.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
              ),
              color: valueOrDefault<Color>(
                _model.switchValue!
                    ? FlutterFlowTheme.of(context).success
                    : FlutterFlowTheme.of(context).error,
                FlutterFlowTheme.of(context).success,
              ),
              letterSpacing: 0.0,
              fontWeight: FlutterFlowTheme.of(context).titleLarge.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
              shadows: [
                Shadow(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  offset: Offset(2.0, 2.0),
                  blurRadius: 2.0,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
