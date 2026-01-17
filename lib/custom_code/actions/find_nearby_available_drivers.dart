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
import 'package:cloud_firestore/cloud_firestore.dart';
// ***** Importación necesaria para GeoFirePoint y GeoPoint *****
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
// ************************************************************
// Importar acción de log personalizada
import '/custom_code/actions/index.dart' as actions;
// LatLng viene de FlutterFlow

// --- La Acción Personalizada (Corregida para buscar Drivers) ---
Future<List<String>?> findNearbyAvailableDrivers(
  // <<-- Nombre cambiado para claridad
  LatLng? businessLocation, // Ubicación de referencia
  double? maxRadiusKm, // Radio de búsqueda
) async {
  // Define el prefijo para los logs
  const String caLogPrefix = '[findNearbyAvailableDrivers V1]';

  // --- Validación ---
  bool isValidLatLng(LatLng? location) {
    if (location == null) return false;
    final lat = location.latitude;
    final lon = location.longitude;
    if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite)
      return false;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
    // Permitir 0,0 como centro de búsqueda si es necesario, aunque usualmente inválido para ubicaciones reales
    // if (lat == 0.0 && lon == 0.0) return false;
    return true;
  }

  if (!isValidLatLng(businessLocation)) {
    await actions.debugLog('Error: businessLocation inválido.', caLogPrefix);
    return null;
  }
  if (maxRadiusKm == null || maxRadiusKm <= 0) {
    await actions.debugLog('Error: maxRadiusKm inválido.', caLogPrefix);
    return null;
  }

  await actions.debugLog(
      'Buscando conductores disponibles cerca de ${businessLocation!.latitude.toStringAsFixed(6)},${businessLocation.longitude.toStringAsFixed(6)} (Radio: ${maxRadiusKm}km)',
      caLogPrefix);

  // --- Preparación ---
  final firestore = FirebaseFirestore.instance;
  // ***** CORRECCIÓN: Apuntar a la colección 'drivers' *****
  final CollectionReference<Map<String, dynamic>> collectionRef =
      firestore.collection('drivers');
  // *******************************************************
  final geoCollectionRef = GeoCollectionReference(collectionRef);
  final centerGeoPoint =
      GeoPoint(businessLocation.latitude, businessLocation.longitude);
  // ***** CORRECCIÓN: Usar GeoFirePoint(GeoPoint(...)) *****
  final centerGeoFirePoint = GeoFirePoint(centerGeoPoint);
  // *******************************************************
  List<String> nearbyAvailableDriverIds =
      []; // Almacenará los IDs de los DOCUMENTOS de drivers

  // --- Ejecución GeoQuery ---
  try {
    await actions.debugLog(
        'Ejecutando fetchWithin en "drivers" campo "currentZone"...',
        caLogPrefix); // <<-- Log actualizado
    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        await geoCollectionRef.fetchWithin(
      center: centerGeoFirePoint,
      radiusInKm: maxRadiusKm,
      // ***** CORRECCIÓN: Usar el campo 'currentZone' de drivers *****
      field: 'currentZone',
      // ***********************************************************
      // Función para extraer el GeoPoint del campo 'currentZone'
      geopointFrom: (data) {
        try {
          // ***** CORRECCIÓN: Extraer de 'currentZone' *****
          final zoneMap = data['currentZone'] as Map<String, dynamic>?;
          // ************************************************
          final geopoint = zoneMap?['geopoint'] as GeoPoint?;
          if (geopoint == null) {
            print(
                "$caLogPrefix ERROR - geopointFrom: GeoPoint nulo en ['currentZone']['geopoint']. Data: $data");
            throw Exception('GeoPoint no encontrado en currentZone.geopoint');
          }
          return geopoint;
        } catch (e) {
          print("$caLogPrefix ERROR CRÍTICO - geopointFrom: $e. Data: $data");
          throw Exception('Error al procesar geopointFrom: $e');
        }
      },
      strictMode: true,
    );

    await actions.debugLog(
        'fetchWithin encontró ${documentSnapshots.length} conductores en radio.', // <<-- Log actualizado
        caLogPrefix);

    // --- Filtrado Post-Query ---
    // ***** CORRECCIÓN: Filtrar por 'isAvailable' de drivers *****
    await actions.debugLog('Filtrando por isAvailable=true...', caLogPrefix);
    // **********************************************************
    for (final doc in documentSnapshots) {
      final data = doc.data();
      final docId = doc.id; // ID del documento en la colección 'drivers'

      // ***** CORRECCIÓN: Usar 'isAvailable' *****
      if (data != null && data['isAvailable'] == true) {
        // *****************************************
        nearbyAvailableDriverIds.add(docId);
        actions.debugLog(
            ' -> Driver ${docId} CERCANO y DISPONIBLE.', // <<-- Log actualizado
            caLogPrefix);
      } else {
        // actions.debugLog(' -> Driver ${docId} OMITIDO (no disponible o datos nulos).', caLogPrefix);
      }
    }

    await actions.debugLog(
        'Encontrados ${nearbyAvailableDriverIds.length} IDs de conductores disponibles y cercanos.', // <<-- Log actualizado
        caLogPrefix);

    // Devolver la lista de IDs de los documentos 'drivers'
    return nearbyAvailableDriverIds;
  } catch (e, s) {
    await actions.debugLog(
        'ERROR CRÍTICO ejecutando fetchWithin o procesando: $e', caLogPrefix);
    await actions.debugLog('Stack trace: $s', caLogPrefix);
    return null; // Devolver null en caso de error
  }
}

/*
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '/custom_code/actions/index.dart' as actions;
// DeliveriesRecord y LatLng vienen de /backend/backend.dart importado automáticamente

// --- Inicio Código Custom Action (con actions.debugLog) ---

Future<List<DeliveriesRecord>?> filterNearbyDeliveries(
  LatLng? driverLocation, // Ubicación del repartidor (centro) - Tipo FF LatLng
  double? maxRadiusKm, // Radio máximo en KM
  List<DeliveriesRecord>? allDeliveries, // Lista COMPLETA de entregas a filtrar
) async {
  // Define el prefijo para los logs de esta acción
  const String caLogPrefix =
      '[CA filterNearbyDeliveries V6 ActionLog]'; // Actualiza versión

  // --- Validación de Entradas (usa actions.debugLog) ---
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
    // Usa tu acción de log
    await actions.debugLog(
        'Error: driverLocation inválido ($driverLocation).', caLogPrefix);
    return null; // Error -> null
  }
  if (maxRadiusKm == null || maxRadiusKm <= 0) {
    // Usa tu acción de log
    await actions.debugLog(
        'Error: maxRadiusKm inválido ($maxRadiusKm).', caLogPrefix);
    return null; // Error -> null
  }
  if (allDeliveries == null) {
    // Usa tu acción de log
    await actions.debugLog(
        'Error: La lista de deliveries es nula.', caLogPrefix);
    return []; // Devuelve lista vacía si el input es null
  }
  if (allDeliveries.isEmpty) {
    // Usa tu acción de log
    await actions.debugLog(
        'Lista de deliveries de entrada está vacía.', caLogPrefix);
    return []; // Retorna lista vacía
  }

  // Usa tu acción de log
  await actions.debugLog(
      'Filtrando ${allDeliveries.length} entregas localmente...', caLogPrefix);
  await actions.debugLog(
      ' -> Centro (Repartidor): ${driverLocation!.latitude.toStringAsFixed(6)}, ${driverLocation.longitude.toStringAsFixed(6)}',
      caLogPrefix);
  await actions.debugLog(' -> Radio: ${maxRadiusKm} km', caLogPrefix);

  List<DeliveriesRecord> nearbyDeliveries = [];

  // --- Iteración y Filtrado Local (usa actions.debugLog) ---
  // El bucle for es síncrono, las llamadas a debugLog aquí son 'fire-and-forget'
  for (final deliveryRecord in allDeliveries) {
    LatLng? originLatLng;
    try {
      // Acceso al campo correcto 'originZone.geopoint'
      originLatLng = deliveryRecord.originZone?.geopoint;
    } catch (e) {
      actions.debugLog(
          'Error accediendo a originZone.geopoint para ${deliveryRecord.reference.id}: $e',
          caLogPrefix); // Async call
      continue;
    }

    if (originLatLng == null) {
      actions.debugLog(
          'Omitiendo ${deliveryRecord.reference.id}: Ubicación de origen (originZone.geopoint) es nula.',
          caLogPrefix); // Async call
      continue;
    }

    try {
      final double distanceInMeters = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        originLatLng.latitude,
        originLatLng.longitude,
      );
      final double distanceInKm = distanceInMeters / 1000.0;

      if (distanceInKm <= maxRadiusKm) {
        nearbyDeliveries.add(deliveryRecord);
        // Log opcional con tu acción
        actions.debugLog(
            ' -> ${deliveryRecord.reference.id} DENTRO del radio (${distanceInKm.toStringAsFixed(2)} km).',
            caLogPrefix); // Async call
      } else {
        // Log opcional con tu acción
        // actions.debugLog(' -> ${deliveryRecord.reference.id} FUERA del radio (${distanceInKm.toStringAsFixed(2)} km).', caLogPrefix); // Async call
      }
    } catch (e) {
      actions.debugLog(
          'Error calculando distancia para ${deliveryRecord.reference.id}: $e',
          caLogPrefix); // Async call
    }
  } // Fin del bucle for

  // --- Ordenación (usa actions.debugLog) ---
  await actions.debugLog(
      'Ordenando ${nearbyDeliveries.length} entregas filtradas por distancia...',
      caLogPrefix);
  try {
    nearbyDeliveries.sort((a, b) {
      final LatLng? pointALatLng = a.originZone?.geopoint;
      final LatLng? pointBLatLng = b.originZone?.geopoint;

      if (pointALatLng == null && pointBLatLng == null) return 0;
      if (pointALatLng == null) return 1;
      if (pointBLatLng == null) return -1;

      try {
        final double distA = Geolocator.distanceBetween(
            driverLocation.latitude,
            driverLocation.longitude,
            pointALatLng.latitude,
            pointALatLng.longitude);
        final double distB = Geolocator.distanceBetween(
            driverLocation.latitude,
            driverLocation.longitude,
            pointBLatLng.latitude,
            pointBLatLng.longitude);
        return distA.compareTo(distB);
      } catch (e) {
        // Usamos print aquí porque no podemos usar await dentro de sort
        print('$caLogPrefix [Sort Error] Calculando distancia: $e');
        return 0;
      }
    });
    await actions.debugLog('Ordenación completada.', caLogPrefix);
  } catch (e) {
    await actions.debugLog('Error durante la ordenación: $e', caLogPrefix);
  }

  await actions.debugLog(
      'Filtrado local completo. Encontradas ${nearbyDeliveries.length} entregas cercanas.',
      caLogPrefix);
  return nearbyDeliveries;
}

// DO NOT REMOVE OR MODIFY THE CODE BELOW!
// End custom action code


*/
