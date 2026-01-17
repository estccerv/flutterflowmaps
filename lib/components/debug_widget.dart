import '/components/debug_logs_widget.dart';
import '/components/tracked_location_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'debug_model.dart';
export 'debug_model.dart';

class DebugWidget extends StatefulWidget {
  const DebugWidget({super.key});

  @override
  State<DebugWidget> createState() => _DebugWidgetState();
}

class _DebugWidgetState extends State<DebugWidget> {
  late DebugModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DebugModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 60,
        maxHeight: MediaQuery.sizeOf(context).height - 150,
      ),
      decoration: BoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          wrapWithModel(
            model: _model.trackedLocationModel,
            updateCallback: () => safeSetState(() {}),
            child: TrackedLocationWidget(),
          ),
          Flexible(
            child: wrapWithModel(
              model: _model.debugLogsModel,
              updateCallback: () => safeSetState(() {}),
              child: DebugLogsWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
