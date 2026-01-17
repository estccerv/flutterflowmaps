// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
// >>> AÑADES ESTA IMPORTACIÓN MANUALMENTE CON EL ALIAS <<<
import '/custom_code/actions/index.dart' as actions;
// LatLng viene de FlutterFlow automáticamente

// --- Variables Globales y Funciones de Logging ---
// Actualiza la versión para reflejar corrección
const String _logPrefix = '[CA getNearbyDeliveries V10 SyncGeopoint]';

// --- ELIMINADA LA FUNCIÓN _log INTERNA ---

// Helper SÍNCRONO para extraer GeoPoint de originZone
// (Se usa print para logs internos aquí)
GeoPoint? _caExtractOriginZoneGeoPointSync(Map<String, dynamic>? data) {
  if (data == null) {
    print("$_logPrefix WARN - _caExtractOriginZoneGeoPointSync: Datos nulos.");
    return null;
  }
  try {
    final originZoneMap = data['originZone'] as Map<String, dynamic>?;
    final geopoint = originZoneMap?['geopoint'] as GeoPoint?;
    if (geopoint == null) {
      print(
          "$_logPrefix WARN - _caExtractOriginZoneGeoPointSync: GeoPoint nulo en ['originZone']['geopoint']. Data: $data");
    }
    return geopoint;
  } catch (e, stackTrace) {
    print(
        "$_logPrefix ERROR - _caExtractOriginZoneGeoPointSync: Fallo. Error: $e");
    print("$_logPrefix Stack: $stackTrace. Data: $data");
    return null;
  }
}

// --- La Custom Action Principal (CORREGIDO geopointFrom) ---
Future<List<dynamic>?> getNearbyDeliveries(
  LatLng? driverLocation, // Ubicación ACTUAL del REPARTIDOR (FF LatLng)
  double? maxRadiusKm, // Radio de búsqueda en KM
) async {
  // Usa tu acción de log
  await actions.debugLog(
      "Inicio de la acción getNearbyDeliveries.", _logPrefix);

  // --- Validación (usa actions.debugLog) ---
  bool isValidLatLng(LatLng? location) {
    if (location == null) return false;
    final lat = location.latitude;
    final lon = location.longitude;
    if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite)
      return false;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
    return true;
  }

  if (!isValidLatLng(driverLocation)) {
    await actions.debugLog(
        'ERROR: driverLocation inválido o nulo ($driverLocation).', _logPrefix);
    return null;
  }
  if (maxRadiusKm == null || maxRadiusKm <= 0) {
    await actions.debugLog(
        'ERROR: maxRadiusKm inválido ($maxRadiusKm).', _logPrefix);
    return null;
  }

  await actions.debugLog(
      'Parámetros válidos. Buscando cerca de Repartidor (${driverLocation!.latitude.toStringAsFixed(6)},${driverLocation.longitude.toStringAsFixed(6)}) / Radio: ${maxRadiusKm}km',
      _logPrefix);

  // --- Preparación ---
  final firestore = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> collectionRef =
      firestore.collection('deliveries');
  final geoCollectionRef = GeoCollectionReference(collectionRef);
  final GeoPoint driverGeoPoint =
      GeoPoint(driverLocation.latitude, driverLocation.longitude);
  final GeoFirePoint centerGeoFirePoint = GeoFirePoint(driverGeoPoint);
  List<dynamic> resultsJsonCompatible = [];

  // --- Ejecución GeoQuery con fetchWithin (CORREGIDO geopointFrom) ---
  try {
    await actions.debugLog(
        'Ejecutando fetchWithin en "deliveries" campo "originZone"...',
        _logPrefix);
    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        await geoCollectionRef.fetchWithin(
      center: centerGeoFirePoint,
      radiusInKm: maxRadiusKm,
      field: 'originZone', // Campo correcto
      // ***** CORRECCIÓN: Función SÍNCRONA para geopointFrom *****
      geopointFrom: (Map<String, dynamic> data) {
        // NO PUEDE SER ASYNC, NO USAR AWAIT AQUÍ
        // Usar el helper síncrono que usa print para logs internos
        final GeoPoint? geopoint = _caExtractOriginZoneGeoPointSync(data);
        if (geopoint == null) {
          // El helper ya imprimió el error detallado
          print(
              "$_logPrefix ERROR - geopointFrom (fetchWithin): GeoPoint nulo devuelto por helper.");
          throw Exception(
              "GeoPoint nulo/no encontrado en 'originZone.geopoint'");
        }
        return geopoint; // Devuelve GeoPoint directamente
      },
      // ********************************************************
      strictMode: true,
    );

    await actions.debugLog(
        'fetchWithin completado. Encontró ${documentSnapshots.length} docs en radio.',
        _logPrefix);

    // --- Filtrado y Ordenación (Lado del Cliente - usa actions.debugLog) ---
    List<Map<String, dynamic>> validDeliveriesForSort = [];
    await actions.debugLog(
        'Iniciando filtrado (status, driverRef) y cálculo distancia...',
        _logPrefix);
    // Bucle síncrono, llamadas a debugLog son fire-and-forget
    for (final docSnapshot in documentSnapshots) {
      final data = docSnapshot.data();
      final docId = docSnapshot.id;

      if (data == null) {
        actions.debugLog(
            "WARN: Doc $docId tiene datos nulos.", _logPrefix); // Async call
        continue;
      }

      final status = data['status'] as String?;
      final driverRef = data['driverRef'];

      if (status == 'pending_assignment' && driverRef == null) {
        actions.debugLog(
            ' -> [$docId] CUMPLE filtro.', _logPrefix); // Async call

        double distanceKm = -1.0;
        // --- USA EL HELPER SÍNCRONO AQUÍ TAMBIÉN ---
        final GeoPoint? originGeoPoint = _caExtractOriginZoneGeoPointSync(data);

        if (originGeoPoint != null) {
          actions.debugLog('    -> Calculando distancia para [$docId]...',
              _logPrefix); // Async call
          try {
            distanceKm = Geolocator.distanceBetween(
                    driverLocation.latitude,
                    driverLocation.longitude,
                    originGeoPoint.latitude,
                    originGeoPoint.longitude) /
                1000.0;
            actions.debugLog(
                '    -> Distancia: ${distanceKm.toStringAsFixed(3)} km',
                _logPrefix); // Async call
          } catch (e) {
            actions.debugLog('    -> ERROR calculando distancia: $e',
                _logPrefix); // Async call
          }
        } else {
          actions.debugLog(
              '    -> WARN: No se pudo calcular distancia (originGeoPoint nulo).',
              _logPrefix); // Async call
        }

        validDeliveriesForSort.add({
          'id': docId,
          'distanceKm': distanceKm,
          'data': data,
        });
      } // Fin if filtro
    } // Fin del bucle for

    await actions.debugLog(
        'Filtrado completo. ${validDeliveriesForSort.length} válidas. Ordenando...',
        _logPrefix);

    // Ordena por distancia
    validDeliveriesForSort.sort((a, b) {
      final double distA = a['distanceKm'] as double? ?? -1.0;
      final double distB = b['distanceKm'] as double? ?? -1.0;
      if (distA < 0 && distB < 0) return 0;
      if (distA < 0) return 1;
      if (distB < 0) return -1;
      return distA.compareTo(distB);
    });

    resultsJsonCompatible = validDeliveriesForSort;
    await actions.debugLog(
        'Ordenación completa. Devolviendo ${resultsJsonCompatible.length} entregas.',
        _logPrefix);

    return resultsJsonCompatible;
  } catch (e, s) {
    // Usa tu acción de log para errores fuera de geopointFrom
    await actions.debugLog(
        'ERROR CRÍTICO ejecutando fetchWithin o procesando: $e', _logPrefix);
    await actions.debugLog('Stack trace: $s', _logPrefix);
    return null;
  }
}
