// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ***** Importación necesaria para GeoFirePoint y GeoPoint *****
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
// ************************************************************
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

// Importar acción de log personalizada (tu formato requerido)
import '/custom_code/actions/index.dart' as actions;

// --- Internal State Variables ---
StreamSubscription<Position>?
    _positionStreamSubscription; // Mobile location stream
StreamSubscription<User?>? _authSubscription; // Firebase Auth changes
StreamSubscription<ServiceStatus>?
    _serviceStatusSubscription; // Mobile location service status
String? _currentTrackingUserId; // UID of the currently logged-in user
DocumentReference?
    _currentDriverDocRef; // Reference to /drivers/{docId} for the user
Timer? _trackStateMonitorTimer; // Timer to check FFAppState().track changes
Timer? _webPollingTimer; // Timer for web location polling
bool _lastReportedTrackState = false; // Last known state of FFAppState().track
LatLng?
    _lastFirestoreUpdateLocationInternal; // Last location successfully SENT to Firestore 'currentZone'

// Log prefix constant
const String _logPrefix = '[TRACKING V4 Schema]'; // Updated log prefix

// --- Configuration Constants ---
const double _minDistanceToUpdateFirestore =
    20.0; // Min distance (meters) to trigger Firestore zone update
const Duration _webPollingInterval =
    Duration(seconds: 10); // How often to check location on Web
const Duration _mobileStreamRestartDelay =
    Duration(seconds: 15); // Delay before retrying mobile stream after error
const Duration _trackStateMonitorInterval =
    Duration(seconds: 1); // How often to check FFAppState().track for changes
const Duration _initialCheckDelay =
    Duration(milliseconds: 500); // Small delay after startup before first check
const Duration _webErrorRetryDelay =
    Duration(seconds: 15); // Delay before retrying web poll after error

/// PUBLIC ACTION: Initializes the driver tracking system.
Future<void> trackDriver() async {
  await actions.debugLog('🚀 Iniciando sistema de seguimiento...', _logPrefix);
  await _cancelAllSubscriptionsAndTimers(); // Clean up any previous state

  // Ensure AppState.trackedLocation is initialized (uses default LatLng(0,0))
  FFAppState().update(() {
    if (FFAppState().trackedLocation == null) {
      FFAppState().trackedLocation = LatLng(0.0, 0.0);
      actions.debugLog(
          '🔄 FFAppState().trackedLocation inicializado.', _logPrefix);
    }
    // Store the initial state of the tracking toggle
    _lastReportedTrackState = FFAppState().track;
  });

  await actions.debugLog(
      '⏳ Esperando ${_initialCheckDelay.inMilliseconds}ms...', _logPrefix);
  await Future.delayed(_initialCheckDelay);

  // Setup authentication listener immediately. It will handle login/logout events.
  _setupAuthenticationListener();

  // If tracking is initially OFF, the system waits for user interaction or login.
  if (!FFAppState().track) {
    await actions.debugLog(
        '⏸️ Tracking inicialmente OFF. Auth Listener configurado.', _logPrefix);
    return; // Don't initialize location services yet
  }

  // If tracking is initially ON, check if user is already logged in.
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await actions.debugLog(
        '▶️ Tracking ON y usuario ${currentUser.uid} logueado. Inicializando...',
        _logPrefix);
    // Set user ID and attempt to find driver ref early
    _currentTrackingUserId = currentUser.uid;
    _currentDriverDocRef = await _getDriverDocRef(
        currentUser.uid); // Important: Find the driver doc
    // Proceed with permission/service checks and location setup
    await _initializeTrackingSystem();
  } else {
    await actions.debugLog(
        '▶️ Tracking ON, pero SIN usuario logueado. Esperando login...',
        _logPrefix);
    // Auth listener will trigger initialization upon successful login.
  }
}

/// Initializes location services (permissions, service check, start stream/poll).
/// Assumes FFAppState().track is true when called.
Future<void> _initializeTrackingSystem() async {
  await actions.debugLog(
      '⚙️ Inicializando sistema de localización (Permisos/Servicio)...',
      _logPrefix);

  // 1. Check Location Permissions
  final permissionStatus = await _checkAndRequestPermissionsIfNeeded();
  if (permissionStatus == LocationPermission.denied ||
      permissionStatus == LocationPermission.deniedForever) {
    await actions.debugLog(
        '❌ Permisos INSUFICIENTES ($permissionStatus). Deteniendo localización.',
        _logPrefix);
    await _stopLocationTracking(); // Stop any location listeners/timers
    // Update Firestore: Mark driver as unavailable if permissions are missing
    if (_currentDriverDocRef != null) {
      await actions.debugLog(
          '   -> Actualizando FS (drivers) a isAvailable=false (Faltan Permisos).',
          _logPrefix);
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
    }
    return; // Cannot proceed without permissions
  }

  // 2. Check Location Service Status
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  await actions.debugLog(
      '⚙️ Servicio de ubicación: ${serviceEnabled ? '✅ ON' : '❌ OFF'}',
      _logPrefix);
  if (!serviceEnabled) {
    await actions.debugLog(
        '⏳ Servicio OFF. Deteniendo localización. Esperando activación...',
        _logPrefix);
    await _stopLocationTracking(); // Stop listeners/timers if service is off
    // On mobile, configure listener to detect when service turns ON
    if (!kIsWeb) {
      _configureMobileServiceListener();
    } else {
      // On web, polling will naturally retry when service becomes available
      await _setupWebLocationTracking(); // Start polling (it will fail until service is on)
    }
    // Update Firestore: Mark driver as unavailable if service is off
    if (_currentDriverDocRef != null) {
      await actions.debugLog(
          '   -> Actualizando FS (drivers) a isAvailable=false (Servicio OFF).',
          _logPrefix);
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
    }
    return; // Cannot get location without service
  }

  // --- Permissions OK & Service ON ---
  await actions.debugLog(
      '🚀 Permisos/Servicio OK. Configurando listeners/polling...', _logPrefix);

  // Ensure mobile service listener is running (if applicable)
  if (!kIsWeb) _configureMobileServiceListener();

  // Start location tracking based on platform
  if (kIsWeb) {
    await _setupWebLocationTracking();
  } else {
    await _setupMobileLocationTracking();
  }

  // Ensure Firestore status is marked as available since everything is OK
  if (_currentDriverDocRef != null && FFAppState().track) {
    await actions.debugLog(
        '   -> Asegurando FS (drivers) isAvailable=true.', _logPrefix);
    await _updateFirestoreDriverStatus(_currentDriverDocRef!, true);
  }
}

/// Checks location permissions and requests them if denied.
Future<LocationPermission> _checkAndRequestPermissionsIfNeeded() async {
  await actions.debugLog('🤔 Chequeando permisos de ubicación...', _logPrefix);
  LocationPermission permission = await Geolocator.checkPermission();
  await actions.debugLog('🔒 Permiso actual (antes): $permission', _logPrefix);

  if (permission == LocationPermission.denied) {
    await actions.debugLog('🔄 Permiso \'denied\', solicitando...', _logPrefix);
    permission = await Geolocator.requestPermission();
    await actions.debugLog(
        '🔒 Permiso después de solicitar: $permission', _logPrefix);
  }

  // Log final permission status for clarity
  if (permission == LocationPermission.deniedForever) {
    await actions.debugLog('❌ Permiso DENEGADO PERMANENTEMENTE.', _logPrefix);
  } else if (permission == LocationPermission.denied) {
    await actions.debugLog('❌ Permiso DENEGADO.', _logPrefix);
  } else {
    await actions.debugLog('✅ Permisos OK ($permission).', _logPrefix);
  }
  return permission;
}

/// Cancels all active Dart Streams and Timers used by the tracking system.
Future<void> _cancelAllSubscriptionsAndTimers() async {
  await actions.debugLog('🧹 Cancelando suscripciones y timers...', _logPrefix);
  // Cancel streams
  await _positionStreamSubscription?.cancel();
  _positionStreamSubscription = null;
  await _authSubscription?.cancel();
  _authSubscription = null;
  await _serviceStatusSubscription?.cancel();
  _serviceStatusSubscription = null;
  // Cancel timers
  _trackStateMonitorTimer?.cancel();
  _trackStateMonitorTimer = null;
  _webPollingTimer?.cancel();
  _webPollingTimer = null;
  // Reset state variables
  _currentTrackingUserId = null;
  _currentDriverDocRef = null; // Crucial: reset driver reference
  _lastFirestoreUpdateLocationInternal = null;
  await actions.debugLog('✅ Suscripciones y timers limpiados.', _logPrefix);
}

/// Finds the `/drivers` document corresponding to a given user ID.
Future<DocumentReference?> _getDriverDocRef(String userId) async {
  await actions.debugLog(
      '🔍 Buscando /drivers doc para User $userId...', _logPrefix);
  try {
    // Get reference to the user document
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    // Query the 'drivers' collection for a document with a matching 'userRef'
    final querySnapshot = await FirebaseFirestore.instance
        .collection('drivers')
        .where('userRef', isEqualTo: userRef)
        .limit(1) // Expect only one driver doc per user
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Driver document found
      final driverDocRef = querySnapshot.docs.first.reference;
      await actions.debugLog(
          '   -> ✅ Encontrado Driver Doc: ${driverDocRef.path}', _logPrefix);
      return driverDocRef;
    } else {
      // No driver document found for this user
      await actions.debugLog(
          '   -> ❌ Documento /drivers NO encontrado para User $userId.',
          _logPrefix);
      return null;
    }
  } catch (e, stackTrace) {
    await actions.debugLog('   -> ❌ Error buscando driver doc: $e', _logPrefix);
    await actions.debugLog('   -> Stack: $stackTrace', _logPrefix);
    return null; // Return null on error
  }
}

/// Sets up the listener for Firebase Authentication state changes (login/logout).
void _setupAuthenticationListener() {
  // Avoid setting up multiple listeners
  if (_authSubscription != null) {
    actions.debugLog(
        '👂 Auth Listener: Ya configurado. Reconfigurando...', _logPrefix);
    _authSubscription!.cancel();
  }
  actions.debugLog('👂 Auth Listener: Configurando...', _logPrefix);

  _authSubscription =
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    final String? previousUserId = _currentTrackingUserId;
    final DocumentReference? driverRefBeforeLogout =
        _currentDriverDocRef; // Store before clearing

    if (user != null) {
      // --- User Logged In or Changed ---
      if (user.uid == _currentTrackingUserId) {
        // User is the same (e.g., token refresh), no action needed for tracking logic
        await actions.debugLog(
            '👤 Auth: Evento para usuario ya rastreado (${user.uid}). Ignorando.',
            _logPrefix);
        return;
      }

      await actions.debugLog(
          '👤✅ Auth: Login/Cambio detectado -> User: ${user.uid}', _logPrefix);
      _currentTrackingUserId = user.uid;
      // CRITICAL: Find the associated driver document for this user
      _currentDriverDocRef = await _getDriverDocRef(user.uid);

      if (_currentDriverDocRef == null) {
        // This user is not associated with a driver document
        await actions.debugLog(
            '👤⚠️ Auth: User ${user.uid} logueado, PERO SIN doc /drivers asociado. Tracking FS no funcionará.',
            _logPrefix);
        // Stop any ongoing location tracking and monitoring for this non-driver user
        await _stopLocationTracking();
        _stopTrackStateMonitor();
        return; // Don't proceed further for non-drivers
      }

      // --- User IS a driver ---
      await actions.debugLog(
          '   -> Usuario es un Driver (${_currentDriverDocRef!.path}).',
          _logPrefix);
      _lastReportedTrackState =
          FFAppState().track; // Sync with current toggle state
      _startTrackStateMonitor(); // Start monitoring the track toggle state

      if (FFAppState().track) {
        // If tracking toggle is ON, initialize location services
        await actions.debugLog(
            '▶️ Auth: track=true. (Re)Activando sistema...', _logPrefix);
        await _initializeTrackingSystem(); // Checks permissions, service, starts tracking
      } else {
        // If tracking toggle is OFF, ensure location is stopped and FS reflects unavailability
        await actions.debugLog(
            '⏸️ Auth: track=false. Sistema inactivo. Asegurando FS isAvailable=false.',
            _logPrefix);
        await _stopLocationTracking(); // Make sure location updates are stopped
        await _updateFirestoreDriverStatus(
            _currentDriverDocRef!, false); // Mark as unavailable in Firestore
      }
    } else {
      // --- User Logged Out ---
      if (previousUserId == null) {
        // Logout event occurred, but no user was being tracked
        await actions.debugLog(
            '👤 Auth: Evento logout, sin usuario rastreado.', _logPrefix);
        return;
      }

      await actions.debugLog(
          '👤❌ Auth: Logout detectado para User: $previousUserId.', _logPrefix);
      // Clear user and driver state
      _currentTrackingUserId = null;
      _currentDriverDocRef = null;

      // Stop monitoring and location tracking
      _stopTrackStateMonitor();
      await _stopLocationTracking();

      // Update Firestore status for the driver who just logged out
      if (driverRefBeforeLogout != null) {
        await actions.debugLog(
            '   -> Actualizando FS (drivers) a isAvailable=false tras logout...',
            _logPrefix);
        await _updateFirestoreDriverStatus(driverRefBeforeLogout, false);
      } else {
        // This case shouldn't happen if logout followed a valid driver login, but log it.
        await actions.debugLog(
            '   -> (Info) No se actualizó FS en logout (sin ref driver previa).',
            _logPrefix);
      }
    }
  });
  actions.debugLog('👂✅ Auth Listener activo.', _logPrefix);
}

/// Configures location tracking using polling for Web platforms.
Future<void> _setupWebLocationTracking() async {
  await actions.debugLog(
      '🌐 Configurando tracking Web (Polling)...', _logPrefix);
  _webPollingTimer?.cancel(); // Stop any existing timer
  _pollWebLocation(); // Start the first poll attempt
}

/// Performs a single location poll attempt on the Web.
void _pollWebLocation() {
  actions.debugLog(
      '🕸️ [Polling] Iniciando ciclo de sondeo Web...', _logPrefix);

  // Use an inner async function to handle awaits cleanly
  Future<void> attemptGetPosition() async {
    // --- Pre-checks: Stop polling if tracking is off or user logs out ---
    if (!FFAppState().track || _currentDriverDocRef == null) {
      await actions.debugLog(
          '🕸️ [Polling] Sondeo OMITIDO (track OFF o sin driver ref).',
          _logPrefix);
      _webPollingTimer?.cancel(); // Ensure timer is stopped
      return;
    }

    try {
      // --- Check Service & Permissions ---
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await actions.debugLog(
            '🕸️❌ [Polling] Servicio Web OFF. Reintentando en ${_webErrorRetryDelay.inSeconds}s...',
            _logPrefix);
        _scheduleNextWebPoll(_webErrorRetryDelay);
        // Mark as unavailable in Firestore if service is off
        await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await actions.debugLog(
            '🕸️❌ [Polling] Permisos Web INSUFICIENTES ($permission). Reintentando en ${_webErrorRetryDelay.inSeconds}s...',
            _logPrefix);
        _scheduleNextWebPoll(_webErrorRetryDelay);
        // Mark as unavailable in Firestore if permissions are lost
        await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
        return;
      }

      // --- Get Location ---
      await actions.debugLog(
          '🕸️ [Polling] Permisos/Servicio OK. Obteniendo posición web...',
          _logPrefix);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        // Set a timeout slightly shorter than the polling interval
        timeLimit: Duration(seconds: _webPollingInterval.inSeconds - 2),
      );

      // --- Process Location ---
      final currentLocation = LatLng(position.latitude, position.longitude);
      await actions.debugLog(
          '🕸️📍 [Polling] Posición Web RECIBIDA: ${currentLocation.latitude.toStringAsFixed(5)}, ${currentLocation.longitude.toStringAsFixed(5)}',
          _logPrefix); // Explicit log upon reception
      _handleNewPosition(currentLocation); // Process the valid location

      // --- Schedule Next Poll ---
      _scheduleNextWebPoll(_webPollingInterval);
    } on TimeoutException {
      // Handle timeout getting location
      await actions.debugLog(
          '🕸️⚠️ [Polling] Timeout obteniendo posición. Reintentando en ${_webPollingInterval.inSeconds}s...',
          _logPrefix);
      _scheduleNextWebPoll(
          _webPollingInterval); // Retry after standard interval
    } on PermissionDeniedException {
      // Handle case where user revokes permission during polling
      LocationPermission currentPermission = await Geolocator.checkPermission();
      await actions.debugLog(
          '🕸️❌ [Polling] Error Permiso Denegado ($currentPermission). Deteniendo sistema.',
          _logPrefix);
      await _stopLocationTracking(); // Stop polling
      await _updateFirestoreDriverStatus(
          _currentDriverDocRef!, false); // Mark unavailable
    } catch (e, stackTrace) {
      // Handle other unexpected errors
      await actions.debugLog(
          '🕸️❌ [Polling] Error inesperado: ${e.toString()}. Reintentando en ${_webErrorRetryDelay.inSeconds}s...',
          _logPrefix);
      await actions.debugLog('[Polling] Stack: $stackTrace', _logPrefix);
      _scheduleNextWebPoll(_webErrorRetryDelay); // Retry after error delay
    }
  }

  attemptGetPosition(); // Call the inner async function
}

/// Schedules the next web polling attempt.
void _scheduleNextWebPoll(Duration delay) {
  _webPollingTimer?.cancel(); // Cancel previous timer
  // Only schedule if tracking is active and we have a driver reference
  if (FFAppState().track && _currentDriverDocRef != null) {
    actions.debugLog(
        '🕸️⏳ [Polling] Agendando próximo chequeo Web en ${delay.inSeconds}s...',
        _logPrefix);
    _webPollingTimer = Timer(delay, _pollWebLocation);
  } else {
    actions.debugLog(
        '🕸️🛑 [Polling] Próximo chequeo NO agendado (track OFF o sin driver ref).',
        _logPrefix);
  }
}

/// Configures location tracking using streams for Mobile platforms.
Future<void> _setupMobileLocationTracking() async {
  if (kIsWeb) return; // Guard: Only run on mobile
  await actions.debugLog(
      '📱 Configurando tracking Móvil (Stream)...', _logPrefix);
  // Attempt to start the stream (will check permissions/service internally)
  await _startMobileLocationStream();
}

/// Configures the listener for Mobile Location Service status changes (ON/OFF).
void _configureMobileServiceListener() {
  if (kIsWeb || _serviceStatusSubscription != null)
    return; // Mobile only, setup once

  actions.debugLog(
      '👂📱 Configurando listener ServiceStatus Móvil...', _logPrefix);
  _serviceStatusSubscription =
      Geolocator.getServiceStatusStream().listen((status) async {
    await actions.debugLog(
        '🔄📱 Estado servicio Móvil cambió a: $status', _logPrefix);

    if (status == ServiceStatus.enabled) {
      // --- Service Turned ON ---
      await actions.debugLog(
          '✅📱 Servicio Móvil ON. Intentando (re)iniciar stream...',
          _logPrefix);
      // Only start the stream if tracking is enabled and we have a driver
      if (FFAppState().track && _currentDriverDocRef != null) {
        await _startMobileLocationStream(); // Attempt to start location updates
        // Consider updating FS status here? Be careful if service flickers.
        // await _updateFirestoreDriverStatus(_currentDriverDocRef!, true);
      } else {
        await actions.debugLog(
            '   -> (Info) Servicio ON, pero tracking inactivo/sin driver.',
            _logPrefix);
      }
    } else {
      // --- Service Turned OFF ---
      await actions.debugLog(
          '🔌📱 Servicio Móvil OFF. Deteniendo stream y actualizando FS...',
          _logPrefix);
      await _positionStreamSubscription
          ?.cancel(); // Stop listening for positions
      _positionStreamSubscription = null;
      // Mark driver as unavailable in Firestore when service is lost
      if (_currentDriverDocRef != null) {
        await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
      }
    }
  });
  actions.debugLog('👂📱✅ Listener ServiceStatus activo.', _logPrefix);
}

/// Starts the location update stream on Mobile platforms.
Future<void> _startMobileLocationStream() async {
  if (kIsWeb) return; // Guard: Mobile only

  // --- Pre-checks: Stop if tracking off or no driver ---
  if (!FFAppState().track || _currentDriverDocRef == null) {
    await actions.debugLog(
        '📱 Stream móvil NO iniciado (track OFF o sin driver ref).',
        _logPrefix);
    await _positionStreamSubscription?.cancel(); // Ensure stream is stopped
    _positionStreamSubscription = null;
    return;
  }

  // Cancel any potentially existing stream before starting anew
  await _positionStreamSubscription?.cancel();
  _positionStreamSubscription = null;
  await actions.debugLog(
      '📱 Intentando iniciar stream ubicación móvil...', _logPrefix);

  // --- Check Permissions & Service Status ---
  LocationPermission permission = await Geolocator.checkPermission();
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (permission != LocationPermission.whileInUse &&
      permission != LocationPermission.always) {
    await actions.debugLog(
        '📱❌ No se inicia stream: Permisos insuficientes ($permission).',
        _logPrefix);
    // Mark unavailable if permissions are missing
    if (_currentDriverDocRef != null)
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
    return;
  }
  if (!serviceEnabled) {
    await actions.debugLog(
        '📱❌ No se inicia stream: Servicio OFF.', _logPrefix);
    // Service listener should handle this, but ensure FS is marked unavailable
    if (_currentDriverDocRef != null)
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
    return;
  }

  // --- Start Stream ---
  await actions.debugLog(
      '📱▶️ Permisos/Servicio OK. Iniciando getPositionStream...', _logPrefix);
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high, // Desired accuracy
    distanceFilter: 5, // Min distance (meters) to trigger an event
  );

  try {
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            // --- Stream Error Handling ---
            .handleError((error) async {
      await actions.debugLog(
          '📱❌ ERROR en Stream: ${error.toString()}', _logPrefix);
      await _positionStreamSubscription?.cancel(); // Stop the broken stream
      _positionStreamSubscription = null;
      // Mark unavailable on stream error
      if (_currentDriverDocRef != null)
        await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
      // Schedule a retry attempt
      await actions.debugLog(
          '📱🔄 Reintentando stream en ${_mobileStreamRestartDelay.inSeconds}s...',
          _logPrefix);
      Timer(_mobileStreamRestartDelay, () {
        // Only retry if tracking is still active and driver exists
        if (FFAppState().track && _currentDriverDocRef != null) {
          _startMobileLocationStream();
        } else {
          actions.debugLog(
              '📱 Reintento stream cancelado (condiciones no cumplidas).',
              _logPrefix);
        }
      });
    })
            // --- Stream Data Handling ---
            .listen(
      (Position position) {
        final currentLocation = LatLng(position.latitude, position.longitude);
        // Log that a position was received from the stream
        actions.debugLog(
            '📱📍 Stream: Posición RECIBIDA: ${currentLocation.latitude.toStringAsFixed(5)}, ${currentLocation.longitude.toStringAsFixed(5)}',
            _logPrefix);
        _handleNewPosition(currentLocation); // Process the location update
      },
      // --- Stream Done Handling ---
      onDone: () async {
        await actions.debugLog(
            '📱🏁 Stream finalizado inesperadamente (onDone). Reintentando...',
            _logPrefix);
        _positionStreamSubscription = null; // Clear subscription
        // Attempt to restart if tracking is still active
        if (FFAppState().track && _currentDriverDocRef != null) {
          Timer(Duration(seconds: 5),
              _startMobileLocationStream); // Short delay before restart attempt
        }
      },
      // Keep subscription alive on error to allow handleError to manage retries
      cancelOnError: false,
    );

    // If stream setup was successful
    await actions.debugLog('📱✅ Stream móvil iniciado con éxito.', _logPrefix);
    // Ensure Firestore reflects available status now that stream is running
    if (_currentDriverDocRef != null)
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, true);
  } catch (e, stackTrace) {
    // Catch errors during the initial Geolocator.getPositionStream setup
    await actions.debugLog(
        '📱❌ Error CRÍTICO al iniciar getPositionStream: ${e.toString()}',
        _logPrefix);
    await actions.debugLog('Stack: $stackTrace', _logPrefix);
    // Mark unavailable if stream setup fails critically
    if (_currentDriverDocRef != null)
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
  }
}

/// PROCESSES a new LatLng received from Web polling or Mobile stream.
/// This is the core function that updates AppState and triggers Firestore updates.
void _handleNewPosition(LatLng currentLocation) {
  // Log entry point for debugging
  actions.debugLog(
      '📍 Procesando nueva posición: ${currentLocation.latitude.toStringAsFixed(5)}, ${currentLocation.longitude.toStringAsFixed(5)}',
      _logPrefix);

  // 1. Validate the received location
  if (!_isValidLocation(currentLocation)) {
    actions.debugLog(
        '   -> ⚠️ Ubicación INVÁLIDA (${currentLocation.latitude}, ${currentLocation.longitude}). Descartada.',
        _logPrefix);
    return; // Ignore invalid locations
  }

  // 2. Update FFAppState().trackedLocation (for UI reactivity)
  // Log BEFORE and AFTER the update to pinpoint issues here
  actions.debugLog(
      '   -> Intentando actualizar FFAppState().trackedLocation...',
      _logPrefix);
  try {
    FFAppState().update(() {
      // Keep this block minimal!
      FFAppState().trackedLocation = currentLocation;
    });
    // Log success IF the update didn't throw an error
    actions.debugLog(
        '   -> ✅ FFAppState().trackedLocation actualizado a: ${FFAppState().trackedLocation?.latitude.toStringAsFixed(5)}, ${FFAppState().trackedLocation?.longitude.toStringAsFixed(5)}',
        _logPrefix);
  } catch (e) {
    // Log any error during the AppState update
    actions.debugLog('   -> ❌ ERROR actualizando FFAppState: $e', _logPrefix);
    // If this fails, the UI won't update. The rest might still work for Firestore.
  }

  // 3. Update Firestore Driver Zone (if conditions met)
  // Requires tracking toggle ON and a valid driver reference
  if (FFAppState().track && _currentDriverDocRef != null) {
    actions.debugLog(
        '   -> Chequeando distancia para update Firestore /drivers/currentZone...',
        _logPrefix);

    // Get the last location successfully sent to Firestore
    final LatLng? lastSentLocation = _getLastFirestoreUpdateLocation();
    double distanceMoved =
        double.infinity; // Default to infinity to force first update

    // Calculate distance if we have a previous location
    if (lastSentLocation != null && _isValidLocation(lastSentLocation)) {
      try {
        distanceMoved = Geolocator.distanceBetween(
            lastSentLocation.latitude,
            lastSentLocation.longitude,
            currentLocation.latitude,
            currentLocation.longitude);
      } catch (e) {
        actions.debugLog(
            '      -> ⚠️ Error calculando distancia FS: $e', _logPrefix);
        distanceMoved = double.infinity; // Force update if distance calc fails
      }
    }

    // Log the calculated distance
    actions.debugLog(
        '      -> Distancia desde último update FS: ${distanceMoved >= 0.1 ? distanceMoved.toStringAsFixed(1) : distanceMoved.toString()}m',
        _logPrefix);

    // Check if distance exceeds the minimum threshold
    if (distanceMoved >= _minDistanceToUpdateFirestore) {
      actions.debugLog(
          '      -> 🟢 >= ${_minDistanceToUpdateFirestore}m. Llamando a _updateFirestoreDriverZone...',
          _logPrefix);
      // Call the async function to update Firestore (don't await here)
      _updateFirestoreDriverZone(_currentDriverDocRef!, currentLocation);
    } else {
      // Optional log: Indicate that Firestore update is skipped due to distance
      // actions.debugLog('      -> ⏸️ < ${_minDistanceToUpdateFirestore}m. Omitiendo update FS zone.', _logPrefix);
    }
  } else {
    // Log if Firestore update is skipped due to tracking toggle or missing driver ref
    actions.debugLog(
        '   -> Omitiendo chequeo Firestore (track OFF o sin driver ref).',
        _logPrefix);
  }
}

// ---- Firestore Update Functions (/drivers collection) ----

/// Updates 'currentZone', 'lastAvailable', and sets 'isAvailable'=true in the DRIVER document.
Future<void> _updateFirestoreDriverZone(
    DocumentReference driverDocRef, LatLng location) async {
  if (!_isValidLocation(location)) {
    await actions.debugLog(
        '❌ FS Zone (Driver): Prevenido envío zona inválida para ${driverDocRef.id}.',
        _logPrefix);
    return;
  }

  await actions.debugLog(
      '▶️ FS Zone (Driver): Actualizando ${driverDocRef.id} -> currentZone a ${location.latitude.toStringAsFixed(5)}...',
      _logPrefix);
  try {
    // Create Firestore GeoPoint and GeoFirePoint
    final geoPoint = GeoPoint(location.latitude, location.longitude);
    final geoFirePoint = GeoFirePoint(geoPoint);
    // Get the Map data {geohash, geopoint} expected by the 'zone' struct
    final zoneData = geoFirePoint.data;

    // Prepare data for Firestore update
    final updateData = {
      'currentZone': zoneData, // Update the zone field
      'lastAvailable': FieldValue.serverTimestamp(), // Update timestamp
      'isAvailable': true, // Ensure status is available
      'lastZone': FieldValue.delete(), // Remove lastZone if present
    };

    // Perform the update
    await driverDocRef.update(updateData);

    // IMPORTANT: Update internal memory ONLY AFTER successful Firestore write
    _setLastFirestoreUpdateLocation(location);

    await actions.debugLog(
        '✅ FS Zone (Driver): currentZone actualizado para ${driverDocRef.id}.',
        _logPrefix);
  } catch (e, stackTrace) {
    // Log errors during Firestore update
    await actions.debugLog(
        '❌ FS Zone (Driver): Error actualizando ${driverDocRef.id}: ${e.toString()}',
        _logPrefix);
    await actions.debugLog('   -> Stack: $stackTrace', _logPrefix);
    // Consider if _lastFirestoreUpdateLocationInternal should be reset on error? Maybe not.
  }
}

/// Updates the general availability status of the DRIVER in Firestore.
/// Handles setting 'isAvailable', 'lastAvailable', and moving location between 'currentZone' and 'lastZone'.
Future<void> _updateFirestoreDriverStatus(
    DocumentReference driverDocRef, bool newIsAvailableState) async {
  await actions.debugLog(
      '▶️ FS Status (Driver): Actualizando ${driverDocRef.id} -> isAvailable=$newIsAvailableState...',
      _logPrefix);

  // Get the latest known location from AppState to use for zone/lastZone
  LatLng? currentLocation = FFAppState().trackedLocation;
  Map<String, dynamic>? zoneDataForUpdate; // To hold {geohash, geopoint} map

  // Prepare zone data if location is valid
  if (currentLocation != null && _isValidLocation(currentLocation)) {
    final geoPoint =
        GeoPoint(currentLocation.latitude, currentLocation.longitude);
    final geoFirePoint = GeoFirePoint(geoPoint);
    zoneDataForUpdate = geoFirePoint.data; // Get the map data
    await actions.debugLog(
        '   -> Usando ubicación de trackedLocation para zona/lastZone: ${currentLocation.latitude.toStringAsFixed(5)}',
        _logPrefix);
  } else {
    await actions.debugLog(
        '   -> (Info) Sin ubicación válida en trackedLocation para zona/lastZone.',
        _logPrefix);
  }

  try {
    // Prepare the base update data
    Map<String, dynamic> dataToUpdate = {
      'isAvailable': newIsAvailableState,
      'lastAvailable': FieldValue
          .serverTimestamp(), // Always update timestamp on status change
    };

    if (newIsAvailableState) {
      // --- Driver is becoming AVAILABLE ---
      await actions.debugLog(
          '   -> Preparando datos ACTIVAR (isAvailable=true)...', _logPrefix);
      // Set currentZone (if location available), delete lastZone
      dataToUpdate['currentZone'] =
          zoneDataForUpdate; // null if no valid location
      dataToUpdate['lastZone'] =
          FieldValue.delete(); // Remove last known location
      // Reset internal memory to force the *next* _handleNewPosition to update currentZone
      _setLastFirestoreUpdateLocation(null);
    } else {
      // --- Driver is becoming UNAVAILABLE ---
      await actions.debugLog(
          '   -> Preparando datos DESACTIVAR (isAvailable=false)...',
          _logPrefix);
      // Set lastZone (if location available), delete currentZone
      dataToUpdate['lastZone'] = zoneDataForUpdate; // Store last known location
      dataToUpdate['currentZone'] = FieldValue.delete(); // Remove active zone
      if (zoneDataForUpdate != null) {
        await actions.debugLog('      -> Guardando lastZone.', _logPrefix);
      } else {
        await actions.debugLog(
            '      -> No se guarda lastZone (sin ubicación válida).',
            _logPrefix);
      }
      // Reset internal memory as currentZone is no longer relevant
      _setLastFirestoreUpdateLocation(null);
    }

    // Perform the Firestore update
    await driverDocRef.update(dataToUpdate);

    await actions.debugLog(
        '✅ FS Status (Driver): Estado actualizado para ${driverDocRef.id}.',
        _logPrefix);
  } catch (e, stackTrace) {
    // Log errors during Firestore status update
    await actions.debugLog(
        '❌ FS Status (Driver): Error actualizando ${driverDocRef.id}: ${e.toString()}',
        _logPrefix);
    await actions.debugLog('   -> Stack: $stackTrace', _logPrefix);
  }
}

// ---- Monitor for FFAppState().track Changes ----

/// Starts the periodic timer to check for changes in `FFAppState().track`.
void _startTrackStateMonitor() {
  // Avoid multiple monitors or starting without a driver
  if (_trackStateMonitorTimer != null || _currentDriverDocRef == null) {
    if (_currentDriverDocRef == null) {
      actions.debugLog(
          '⏱️ Monitor Track NO iniciado (sin driver ref).', _logPrefix);
    }
    return;
  }
  actions.debugLog(
      '⏱️ Iniciando monitor FFAppState().track (Intervalo: ${_trackStateMonitorInterval.inSeconds}s)...',
      _logPrefix);

  // Check status immediately when starting
  _checkAndUpdateTrackStatus();

  // Start the periodic timer
  _trackStateMonitorTimer = Timer.periodic(_trackStateMonitorInterval, (timer) {
    // Stop monitor if user logs out or driver ref is lost
    if (_currentDriverDocRef == null) {
      actions.debugLog(
          '⏱️🛑 Monitor Track detenido (sin driver ref / logout).', _logPrefix);
      timer.cancel();
      _trackStateMonitorTimer = null;
      return;
    }
    // Check the toggle state periodically
    _checkAndUpdateTrackStatus();
  });
}

/// Stops the periodic timer monitoring `FFAppState().track`.
void _stopTrackStateMonitor() {
  if (_trackStateMonitorTimer != null) {
    actions.debugLog('⏱️🛑 Deteniendo monitor FFAppState().track.', _logPrefix);
    _trackStateMonitorTimer!.cancel();
    _trackStateMonitorTimer = null;
  }
}

/// Checks if `FFAppState().track` has changed and triggers appropriate actions.
Future<void> _checkAndUpdateTrackStatus() async {
  // Should only run if we have a driver reference
  if (_currentDriverDocRef == null) return;

  final currentTrackState = FFAppState().track; // Get current toggle value

  // Compare with the last known state
  if (currentTrackState != _lastReportedTrackState) {
    await actions.debugLog(
        '🔄 Monitor: Cambio detectado: FFAppState().track -> $currentTrackState (era $_lastReportedTrackState).',
        _logPrefix);

    // Update the last known state
    _lastReportedTrackState = currentTrackState;

    if (currentTrackState) {
      // --- Tracking was just TURNED ON ---
      await actions.debugLog(
          '🟢 Monitor: Track ACTIVADO por usuario. (Re)Activando sistema y FS (drivers)...',
          _logPrefix);
      // Initialize location services (checks permissions, service, starts stream/poll)
      await _initializeTrackingSystem();
      // Explicitly ensure FS status is updated (initialize might do it, but belt-and-suspenders)
      // await _updateFirestoreDriverStatus(_currentDriverDocRef!, true);
    } else {
      // --- Tracking was just TURNED OFF ---
      await actions.debugLog(
          '🔴 Monitor: Track DESACTIVADO por usuario. Deteniendo ubicación y FS (drivers)...',
          _logPrefix);
      // Stop location streams/polling
      await _stopLocationTracking();
      // Update Firestore to mark driver as unavailable
      await _updateFirestoreDriverStatus(_currentDriverDocRef!, false);
    }
  }
}

// --- Helper Functions ---

/// Stops active location streams (Mobile) or polling (Web).
Future<void> _stopLocationTracking() async {
  await actions.debugLog(
      '🔌 Deteniendo listeners/polling de ubicación...', _logPrefix);
  // Stop mobile stream
  await _positionStreamSubscription?.cancel();
  _positionStreamSubscription = null;
  // Stop web polling timer
  _webPollingTimer?.cancel();
  _webPollingTimer = null;
  await actions.debugLog(
      '✅ Listeners/polling de ubicación detenidos.', _logPrefix);
}

/// Validates if a LatLng object contains realistic coordinates and is not (0,0).
bool _isValidLocation(LatLng? location) {
  if (location == null) return false;
  final lat = location.latitude;
  final lon = location.longitude;
  // Check for NaN or infinite values
  if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite) return false;
  // Check for valid geographical range
  if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) return false;
  // Check for the specific (0,0) case, often indicating an invalid/default location
  if (lat == 0.0 && lon == 0.0) return false;
  // If all checks pass, the location is considered valid
  return true;
}

// --- Internal State Management for Last Firestore Update Location ---

/// Gets the last location that was successfully sent to Firestore 'currentZone'.
LatLng? _getLastFirestoreUpdateLocation() {
  return _lastFirestoreUpdateLocationInternal;
}

/// Sets the internal memory of the last location sent to Firestore 'currentZone'.
/// This is crucial for the distance filter logic.
void _setLastFirestoreUpdateLocation(LatLng? location) {
  // Check if the location actually changed to avoid redundant logging/updates
  bool changed = false;
  if (location == null && _lastFirestoreUpdateLocationInternal != null) {
    // Changed from a valid location to null
    changed = true;
  } else if (location != null &&
      (_lastFirestoreUpdateLocationInternal == null ||
          location.latitude != _lastFirestoreUpdateLocationInternal!.latitude ||
          location.longitude !=
              _lastFirestoreUpdateLocationInternal!.longitude)) {
    // Changed from null to a valid location, or coordinates changed
    changed = true;
  }

  // If the location changed, update the internal state and log it
  if (changed) {
    _lastFirestoreUpdateLocationInternal =
        location; // Update the state variable
    if (location != null) {
      actions.debugLog(
          '💾 Memoria: Última ubicación FS guardada -> ${location.latitude.toStringAsFixed(5)}',
          _logPrefix);
    } else {
      // Log when the internal memory is reset (e.g., on deactivate, status update)
      actions.debugLog(
          '💾 Memoria: Última ubicación FS reseteada (null).', _logPrefix);
    }
  }
}
// End custom action code
