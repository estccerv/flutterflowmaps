// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// --- IMPORTACIONES NECESARIAS ---
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show min, max;
import 'package:flutter/foundation.dart';
import '/custom_code/actions/debug_log.dart';
// ---------------------------------

// Helper function para decodificar la polilínea.
List<maps.LatLng> decodePolyline(String encoded) {
  List<maps.LatLng> points = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    points.add(maps.LatLng(lat / 1E5, lng / 1E5));
  }
  return points;
}

class RouteTripper extends StatefulWidget {
  const RouteTripper({
    super.key,
    this.width,
    this.height,
    this.origin,
    this.destination,
    this.routeColor,
    this.originMarkerColor,
    this.destinationMarkerColor,
    required this.getGoogleDirectionsEndpoint,
    required this.googleMapsApiKey,
  });

  final double? width;
  final double? height;
  final LatLng? origin;
  final LatLng? destination;
  final Color? routeColor;
  final Color? originMarkerColor;
  final Color? destinationMarkerColor;
  final String getGoogleDirectionsEndpoint;
  final String googleMapsApiKey;

  @override
  State<RouteTripper> createState() => _RouteTripperState();
}

class _RouteTripperState extends State<RouteTripper> {
  final String _logPrefix = '[RouteTripper-SUAVE]';
  final Completer<maps.GoogleMapController> _mapController = Completer();

  Set<maps.Marker> _markers = {};
  Set<maps.Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndDrawRoute();
  }

  @override
  void didUpdateWidget(RouteTripper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.origin != oldWidget.origin ||
        widget.destination != oldWidget.destination) {
      _fetchAndDrawRoute();
    }
  }

  Future<void> _fetchAndDrawRoute() async {
    if (mounted) setState(() => _isLoading = true);

    if (widget.origin == null || widget.destination == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final Set<maps.Marker> newMarkers = {};
    final Set<maps.Polyline> newPolylines = {};

    newMarkers.add(maps.Marker(
      markerId: maps.MarkerId("origin"),
      position: maps.LatLng(widget.origin!.latitude, widget.origin!.longitude),
      icon: maps.BitmapDescriptor.defaultMarkerWithHue(
          _getColorHue(widget.originMarkerColor ?? Colors.green)),
    ));
    newMarkers.add(maps.Marker(
      markerId: maps.MarkerId("destination"),
      position: maps.LatLng(
          widget.destination!.latitude, widget.destination!.longitude),
      icon: maps.BitmapDescriptor.defaultMarkerWithHue(
          _getColorHue(widget.destinationMarkerColor ?? Colors.red)),
    ));

    try {
      final originString =
          '${widget.origin!.latitude},${widget.origin!.longitude}';
      final destinationString =
          '${widget.destination!.latitude},${widget.destination!.longitude}';
      final url = Uri.parse(
          '${widget.getGoogleDirectionsEndpoint}?origin=$originString&destination=$destinationString');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = getJsonField(data, r'''$.routes''');

        if (routes != null && (routes is List) && routes.isNotEmpty) {
          final overviewPolyline =
              getJsonField(routes.first, r'''$.overview_polyline.points''');
          if (overviewPolyline is String && overviewPolyline.isNotEmpty) {
            // ----- ¡LA SOLUCIÓN A LA RUTA "ZIG-ZAG"! -----
            newPolylines.add(maps.Polyline(
              polylineId: maps.PolylineId("api_route"),
              points: decodePolyline(overviewPolyline),
              color: widget.routeColor ?? Colors.blueAccent,
              width: 5,
              // Estas 3 líneas convierten las esquinas duras en curvas suaves.
              jointType: maps.JointType.round,
              startCap: maps.Cap.roundCap,
              endCap: maps.Cap.roundCap,
            ));
            // --------------------------------------------------
          }
        }
      } else {
        // Plan B: Dibujar línea recta si la API falla.
        newPolylines.add(maps.Polyline(
          polylineId: maps.PolylineId("fallback_line"),
          points: [
            maps.LatLng(widget.origin!.latitude, widget.origin!.longitude),
            maps.LatLng(
                widget.destination!.latitude, widget.destination!.longitude)
          ],
          color: Colors.grey,
          width: 4,
          patterns: [maps.PatternItem.dot, maps.PatternItem.gap(10)],
        ));
      }
    } catch (e) {
      await debugLog('ERROR CRÍTICO: $e. Dibujando línea recta.', _logPrefix);
      newPolylines.add(maps.Polyline(
        polylineId: maps.PolylineId("fallback_line"),
        points: [
          maps.LatLng(widget.origin!.latitude, widget.origin!.longitude),
          maps.LatLng(
              widget.destination!.latitude, widget.destination!.longitude)
        ],
        color: Colors.red,
        width: 4,
        patterns: [maps.PatternItem.dot, maps.PatternItem.gap(10)],
      ));
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
        _isLoading = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _zoomToFitMarkers());
  }

  Future<void> _zoomToFitMarkers() async {
    if (widget.origin == null ||
        widget.destination == null ||
        !_mapController.isCompleted) return;

    final controller = await _mapController.future;
    final bounds = maps.LatLngBounds(
      southwest: maps.LatLng(
          min(widget.origin!.latitude, widget.destination!.latitude),
          min(widget.origin!.longitude, widget.destination!.longitude)),
      northeast: maps.LatLng(
          max(widget.origin!.latitude, widget.destination!.latitude),
          max(widget.origin!.longitude, widget.destination!.longitude)),
    );
    controller.animateCamera(maps.CameraUpdate.newLatLngBounds(bounds, 60.0));
  }

  double _getColorHue(Color color) {
    HSLColor hslColor = HSLColor.fromColor(color);
    return hslColor.hue;
  }

  @override
  Widget build(BuildContext context) {
    final maps.LatLng initialTarget = widget.origin != null
        ? maps.LatLng(widget.origin!.latitude, widget.origin!.longitude)
        : maps.LatLng(0, 0);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          maps.GoogleMap(
            initialCameraPosition: maps.CameraPosition(
              target: initialTarget,
              zoom: 14,
            ),
            onMapCreated: (maps.GoogleMapController controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
