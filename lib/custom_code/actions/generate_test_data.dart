// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart'; // Asegúrate de tener faker: ^2.1.0 en dependencias FF
// ***** Importación necesaria para GeoFirePoint y GeoPoint *****
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
// ************************************************************
// Importar acción de log personalizada con alias
import '/custom_code/actions/index.dart' as actions;

Future<void> generateTestData() async {
  // Acción para crear solo:
  // 1. Un usuario Cliente (users)
  // 2. Un usuario Dueño de Negocio (users)
  // 3. Un negocio (businesses) asociado al dueño
  // 4. Una orden (orders) del cliente al negocio
  // Listo para ser usado por la Cloud Function createDeliveriesNotification

  final firestore = FirebaseFirestore.instance;
  final faker = Faker();
  final random = Random();

  // Prefijo para logs
  const String logPrefix = '[generateSimplifiedTestData]';

  await actions.debugLog(
      'Iniciando generación SIMPLIFICADA de datos...', logPrefix);

  // --- Coordenadas Objetivo (para generar ubicaciones cercanas) ---
  final List<GeoPoint> targetGeoPoints = [
    const GeoPoint(-3.8633472, -79.6295168), // Ejemplo 1
    const GeoPoint(-2.1194483, -79.8833917), // Ejemplo 2
    // Puedes añadir más puntos base si quieres más variedad geográfica
  ];

  // --- Helper para generar 'zone' (Map {geohash, geopoint}) ---
  Map<String, dynamic> generateZoneNearTargets() {
    final baseGeoPoint =
        targetGeoPoints[random.nextInt(targetGeoPoints.length)];
    const double maxOffset =
        0.01; // Aumentar un poco para más dispersión si se desea
    final latOffset = (random.nextDouble() * 2 - 1) * maxOffset;
    final lonOffset = (random.nextDouble() * 2 - 1) * maxOffset;
    // Asegurar que la longitud se mantenga en el rango [-180, 180]
    final finalLon = (baseGeoPoint.longitude + lonOffset + 180) % 360 - 180;
    final finalLat =
        (baseGeoPoint.latitude + latOffset).clamp(-90.0, 90.0); // Clamp latitud
    final finalGeoPoint = GeoPoint(finalLat, finalLon);
    // Usar geoflutterfire_plus para obtener geohash y geopoint juntos
    final geoFirePoint = GeoFirePoint(finalGeoPoint);
    // Retornar el mapa como se espera en Firestore {geohash: ..., geopoint: ...}
    return geoFirePoint.data;
  }

  // --- Helper para generar 'location' (Map {address, zone}) ---
  Map<String, dynamic> generateLocationNearTargets() {
    final zoneData = generateZoneNearTargets();
    final addressData = faker.address.streetAddress();
    return {'address': addressData, 'zone': zoneData};
  }

  try {
    // --- 1. Crear Usuarios (Cliente y Dueño) ---
    await actions.debugLog('Creando usuarios (Cliente y Dueño)...', logPrefix);
    DocumentReference? customerRef;
    Map<String, dynamic>? customerLocation;
    Map<String, dynamic>? customerInfoForEmbedding;

    DocumentReference? ownerRef;
    // No necesitamos la ubicación ni el info del dueño para la orden simplificada

    for (int i = 0; i < 2; i++) {
      final userEmail = faker.internet.email();
      final generatedDisplayName = faker.person.name();
      final generatedPhoneNumber =
          faker.phoneNumber.us(); // O el formato que uses
      final currentUserLocation = generateLocationNearTargets();

      // Datos según schema 'users' simplificado
      final userData = {
        'email': userEmail,
        'display_name': generatedDisplayName, // Nombre de campo correcto
        'phone_number': generatedPhoneNumber, // Nombre de campo correcto
        'locations': [currentUserLocation],
        // Campos opcionales no necesarios para este test:
        // 'isOnline': random.nextBool(),
        // 'lastOnline': Timestamp.now(),
        // 'driverRef': null,
      };

      final userRef = await firestore.collection('users').add(userData);
      await actions.debugLog('Usuario creado: ${userRef.id}', logPrefix);

      if (i == 0) {
        // Primer usuario es el Cliente
        customerRef = userRef;
        customerLocation = currentUserLocation;
        // Crear estructura userInfo para embeber en la orden
        customerInfoForEmbedding = {
          'uid': userRef.id,
          'display_name': generatedDisplayName, // Nombre de campo correcto
          'email': userEmail,
          'phone_number': generatedPhoneNumber, // Nombre de campo correcto
        };
      } else {
        // Segundo usuario es el Dueño del negocio
        ownerRef = userRef;
      }
    }

    // Validar que se crearon las referencias necesarias
    if (customerRef == null ||
        ownerRef == null ||
        customerLocation == null ||
        customerInfoForEmbedding == null) {
      throw Exception("Fallo al crear referencias de usuario cliente o dueño.");
    }

    await actions.debugLog(
        'Cliente Ref: ${customerRef.id}, Dueño Ref: ${ownerRef.id}', logPrefix);

    // --- 2. Crear Negocio ---
    await actions.debugLog('Creando negocio (schema businesses)...', logPrefix);
    final currentBusinessLocation = generateLocationNearTargets();
    final businessName = faker.company.name();
    final businessPhoneNumber = faker.phoneNumber.us(); // O formato deseado

    // Datos según schema 'businesses'
    final businessData = {
      'status': 'active', // O el estado inicial que prefieras
      'name': businessName,
      'location': currentBusinessLocation,
      'phoneNumber': businessPhoneNumber,
      'ownersRefs': [ownerRef], // Referencia al usuario dueño creado
    };
    final businessRef =
        await firestore.collection('businesses').add(businessData);
    await actions.debugLog('Negocio creado: ${businessRef.id}', logPrefix);

    // Crear estructura businessInfo para embeber en la orden
    final businessInfoForEmbedding = {
      'uid': businessRef.id,
      'name': businessName,
      'address': currentBusinessLocation['address'],
      'phoneNumber': businessPhoneNumber,
    };

    // --- 3. Crear Orden ---
    await actions.debugLog('Creando orden (schema orders)...', logPrefix);
    // Estado inicial de la orden, p.ej., 'pending', 'confirmed', etc.
    // 'ready_for_pickup' podría ser un estado si quieres simular ese flujo
    final orderStatus = 'confirmed'; // O 'pending', etc.

    // Datos según schema 'orders' simplificado
    final orderData = {
      'status': orderStatus,
      'customer': customerInfoForEmbedding, // userInfo del cliente
      'business': businessInfoForEmbedding, // businessInfo del negocio
      'customerRef': customerRef, // Referencia al doc del cliente
      'businessRef': businessRef, // Referencia al doc del negocio
      'customerZone': customerLocation['zone'], // Zona del cliente
      'businessZone': currentBusinessLocation['zone'], // Zona del negocio
      // Campos NO necesarios en esta etapa (serán poblados por otros procesos):
      // 'driver': null,
      // 'driverRef': null,
      // 'deliveryRef': null,
    };
    final orderRef = await firestore.collection('orders').add(orderData);
    await actions.debugLog('Orden creada: ${orderRef.id}', logPrefix);
    await actions.debugLog('-> Cliente: ${customerRef.id}', logPrefix);
    await actions.debugLog('-> Negocio: ${businessRef.id}', logPrefix);
    await actions.debugLog(
        '-> Zona Cliente: ${customerLocation['zone']['geohash']}', logPrefix);
    await actions.debugLog(
        '-> Zona Negocio: ${currentBusinessLocation['zone']['geohash']}',
        logPrefix);

    // --- Fin ---
    await actions.debugLog(
        '\n¡Generación SIMPLIFICADA de datos completada!', logPrefix);
    await actions.debugLog(
        'Orden ID para usar en Cloud Function: ${orderRef.id}', logPrefix);
  } catch (e, s) {
    // Manejo de errores
    await actions.debugLog(
        'ERROR CRÍTICO durante generación simplificada: $e', logPrefix);
    await actions.debugLog('Stack trace: $s', logPrefix);
    // Puedes relanzar el error si quieres que la acción falle en FlutterFlow
    // throw e;
  }
}
// End custom action code
