// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para GeoPoint

Future<ZoneStruct?> generateCurrentZone(LatLng? location) async {
  // 1. Validar la entrada
  if (!_isValidLocation(location)) {
    // Puedes añadir un log si quieres, pero en funciones a veces es mejor solo devolver null.
    // print('[generateCurrentZone] Error: Ubicación de entrada nula o inválida.');
    return null; // Devuelve null si la ubicación no es válida
  }

  // Como _isValidLocation ya chequeó que no sea null, podemos usar '!'
  final validLocation = location!;

  try {
    // 2. Crear GeoPoint de Firestore
    // GeoFirePoint necesita un GeoPoint de Firestore.
    final geoPoint = GeoPoint(validLocation.latitude, validLocation.longitude);

    // 3. Crear GeoFirePoint usando geoflutterfire_plus
    final geoFirePoint = GeoFirePoint(geoPoint);

    // 4. Obtener el geohash
    final String geohash = geoFirePoint.geohash;

    // 5. Crear y devolver la ZoneStruct
    // Asume que ZoneStruct tiene los campos 'geohash' (String) y 'geopoint' (LatLng)
    // Se usa la 'validLocation' (LatLng original) para el campo 'geopoint' de la struct,
    // ya que eso es lo que FlutterFlow usualmente maneja internamente en structs/AppState.
    // Firestore se encargará de la conversión LatLng -> GeoPoint al guardar si el tipo de dato es correcto en la BD.
    return ZoneStruct(
      geohash: geohash,
      geopoint: validLocation, // Usamos la LatLng original válida
    );
  } catch (e) {
    // En caso de cualquier error durante la creación de GeoPoint/GeoFirePoint
    print('[generateCurrentZone] Error creando ZoneStruct: $e');
    return null; // Devuelve null en caso de error
  }
}

// Helper function para validar LatLng (copiada de tu código de trackDriver)
// Es buena práctica tenerla aquí si no está disponible globalmente.
bool _isValidLocation(LatLng? location) {
  if (location == null) return false;
  final lat = location.latitude;
  final lon = location.longitude;
  // Check for NaN or infinite values
  if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite) return false;
  // Check for valid geographical range
  if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) return false;
  // Check for the specific (0,0) case, often indicating an invalid/default location
  // Ajusta esto si (0,0) es una ubicación válida en tu caso de uso.
  if (lat == 0.0 && lon == 0.0) return false;
  // If all checks pass, the location is considered valid
  return true;
}
