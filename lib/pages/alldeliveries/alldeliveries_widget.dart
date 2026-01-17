import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'alldeliveries_model.dart';
export 'alldeliveries_model.dart';

class AlldeliveriesWidget extends StatefulWidget {
  const AlldeliveriesWidget({super.key});

  static String routeName = 'alldeliveries';
  static String routePath = '/alldeliveries';

  @override
  State<AlldeliveriesWidget> createState() => _AlldeliveriesWidgetState();
}

class _AlldeliveriesWidgetState extends State<AlldeliveriesWidget> {
  late AlldeliveriesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AlldeliveriesModel());

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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: custom_widgets.NearbyDeliveries(
              width: double.infinity,
              height: double.infinity,
              maxRadiusKm: 1000.0,
              driverLocation: FFAppState().trackedLocation,
            ),
          ),
        ),
      ),
    );
  }
}
