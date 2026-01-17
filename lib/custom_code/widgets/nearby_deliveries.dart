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

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
// Asegúrate que la ruta a tu ListWidget sea correcta y que ListWidget acepte un parámetro `deliveries` de tipo `List<DeliveriesRecord>`
import '/components/list_widget.dart' as custom_deliveries_component;
import '/custom_code/actions/index.dart' as actions; // Importa tu acción de log

class NearbyDeliveries extends StatefulWidget {
  const NearbyDeliveries({
    super.key,
    this.width,
    this.height,
    this.driverLocation, // LatLng de FlutterFlow (Ubicación actual del conductor)
    this.maxRadiusKm, // Radio de búsqueda en Km
  });

  final double? width;
  final double? height;
  final LatLng? driverLocation;
  final double? maxRadiusKm;

  @override
  State<NearbyDeliveries> createState() => _NearbyDeliveriesState();
}

class _NearbyDeliveriesState extends State<NearbyDeliveries> {
  // Stream para escuchar las entregas cercanas desde Firestore
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>>? _deliveriesStream;

  // Prefijo para identificar los logs de este widget
  static const String _logPrefix = '[NearbyDeliveriesWidget V11 Full]';

  // --- Helper SÍNCRONO para extraer GeoPoint de 'originZone' ---
  // Usa 'print' para logs internos porque esta función NO puede ser async
  GeoPoint? _extractOriginZoneGeoPointSync(Map<String, dynamic>? data) {
    if (data == null) {
      print("$_logPrefix WARN - _extractOriginZoneGeoPointSync: Datos nulos.");
      return null;
    }
    try {
      // Accede al mapa 'originZone'
      final originZoneMap = data['originZone'] as Map<String, dynamic>?;
      // Accede al campo 'geopoint' dentro de 'originZone'
      final geopoint = originZoneMap?['geopoint'] as GeoPoint?;
      if (geopoint == null) {
        print(
            "$_logPrefix WARN - _extractOriginZoneGeoPointSync: GeoPoint nulo en ['originZone']['geopoint']. Data: $data");
      }
      // Retorna el GeoPoint (o null si no se encontró)
      return geopoint;
    } catch (e, stackTrace) {
      // Captura cualquier error durante el acceso a los datos
      print(
          "$_logPrefix ERROR - _extractOriginZoneGeoPointSync: Fallo al extraer GeoPoint. Error: $e");
      print("$_logPrefix Stack: $stackTrace. Data: $data");
      return null; // Retorna null en caso de error
    }
  }

  @override
  void initState() {
    super.initState();
    // Usa la acción de log personalizada (es async, pero fire-and-forget aquí)
    actions.debugLog(
        'initState: Widget inicializado. Configurando stream...', _logPrefix);
    // Llama a la función asíncrona para configurar el stream inicial
    _initializeStream();
  }

  @override
  void didUpdateWidget(covariant NearbyDeliveries oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Log detallado para depurar cambios en los parámetros
    actions.debugLog(
        'didUpdateWidget Check: Old Loc: ${oldWidget.driverLocation}, New Loc: ${widget.driverLocation}',
        _logPrefix);
    actions.debugLog(
        'didUpdateWidget Check: Old Rad: ${oldWidget.maxRadiusKm}, New Rad: ${widget.maxRadiusKm}',
        _logPrefix);

    // Comprueba si la ubicación del conductor ha cambiado significativamente
    // Se compara latitud y longitud por separado para evitar problemas con instancias de LatLng
    final bool locationChanged = oldWidget.driverLocation?.latitude !=
            widget.driverLocation?.latitude ||
        oldWidget.driverLocation?.longitude != widget.driverLocation?.longitude;

    // Comprueba si el radio de búsqueda ha cambiado
    final bool radiusChanged = oldWidget.maxRadiusKm != widget.maxRadiusKm;

    actions.debugLog(
        'didUpdateWidget Result: Location Changed: $locationChanged, Radius Changed: $radiusChanged',
        _logPrefix);

    // Si la ubicación o el radio han cambiado...
    if (locationChanged || radiusChanged) {
      actions.debugLog(
          'didUpdateWidget: Parámetros cambiaron. Reiniciando stream...',
          _logPrefix);
      // ...vuelve a inicializar el stream con los nuevos parámetros
      _initializeStream();
    } else {
      // Log opcional si no hubo cambios detectados
      actions.debugLog(
          'didUpdateWidget: Parámetros sin cambios detectados.', _logPrefix);
    }
  }

  @override
  void dispose() {
    // Log cuando el widget se elimina del árbol
    actions.debugLog('dispose: Widget eliminado.', _logPrefix);
    // (No es necesario cancelar el stream manualmente si se usa StreamBuilder,
    // Flutter se encarga, pero buena práctica si se manejan suscripciones manuales)
    super.dispose();
  }

  // --- Lógica Principal: Configuración del Stream de Firestore ---
  Future<void> _initializeStream() async {
    // 1. Validación de Parámetros de Entrada
    if (!_isValidLatLng(widget.driverLocation)) {
      await actions.debugLog(
          'ERROR (_initializeStream): driverLocation inválido (${widget.driverLocation}). No se inicia stream.',
          _logPrefix);
      // Configura un stream vacío si la ubicación no es válida
      _setEmptyStream();
      return; // Detiene la ejecución si los parámetros no son válidos
    }
    if (widget.maxRadiusKm == null || widget.maxRadiusKm! <= 0) {
      await actions.debugLog(
          'ERROR (_initializeStream): maxRadiusKm inválido (${widget.maxRadiusKm}). No se inicia stream.',
          _logPrefix);
      // Configura un stream vacío si el radio no es válido
      _setEmptyStream();
      return; // Detiene la ejecución
    }

    // 2. Preparación para la GeoQuery
    final firestore = FirebaseFirestore.instance;
    // Referencia a la colección 'deliveries'
    final CollectionReference<Map<String, dynamic>> collectionRef =
        firestore.collection('deliveries');
    // Wrapper Geo para la colección
    final geoCollectionRef = GeoCollectionReference(collectionRef);
    // Convierte el LatLng del widget a un GeoPoint de Firestore
    final GeoPoint centerGeoPoint = GeoPoint(
        widget.driverLocation!.latitude, widget.driverLocation!.longitude);
    // Convierte el GeoPoint a un GeoFirePoint para la librería geoflutterfire_plus
    final GeoFirePoint centerGeoFirePoint = GeoFirePoint(centerGeoPoint);

    await actions.debugLog(
        'initializeStream: Preparando suscripción con Centro=${centerGeoPoint.latitude.toStringAsFixed(6)},${centerGeoPoint.longitude.toStringAsFixed(6)}, Radio=${widget.maxRadiusKm}km',
        _logPrefix);

    // 3. Suscripción al Stream (Asegurarse que el widget sigue montado)
    if (mounted) {
      // setState es síncrono y actualiza la UI para usar el nuevo stream
      setState(() {
        // Crea la suscripción al stream de documentos dentro del radio
        _deliveriesStream = geoCollectionRef
            .subscribeWithin(
          center: centerGeoFirePoint, // Punto central de la búsqueda
          radiusInKm: widget.maxRadiusKm!, // Radio de búsqueda
          field:
              'originZone', // Campo que contiene la ubicación a buscar (¡importante!)
          // Función OBLIGATORIA y SÍNCRONA para extraer el GeoPoint del documento
          geopointFrom: (Map<String, dynamic> data) {
            // NO PUEDE SER ASYNC. Usa el helper síncrono.
            final GeoPoint? geopoint = _extractOriginZoneGeoPointSync(data);
            // Si el helper no pudo extraer el GeoPoint, lanza una excepción
            // para que geoflutterfire_plus lo maneje (o lo ignore si strictMode=false)
            if (geopoint == null) {
              // El helper ya imprimió el error detallado
              print(
                  "$_logPrefix ERROR - geopointFrom (en subscribeWithin): GeoPoint nulo devuelto por helper. Data: $data");
              // Es crucial lanzar una excepción si no se encuentra el geopoint
              // y strictMode es true (valor por defecto)
              throw Exception(
                  "GeoPoint nulo/no encontrado en el campo 'originZone.geopoint'");
            }
            // Devuelve el GeoPoint encontrado
            return geopoint;
          },
          // strictMode: true (por defecto) -> Lanza error si geopointFrom falla
          // strictMode: false -> Ignora documentos donde geopointFrom falla
          strictMode: true,
        )
            // Manejo de errores en el stream mismo
            .handleError((error, stackTrace) async {
          // Hacer el cuerpo de handleError async para usar actions.debugLog
          await actions.debugLog(
              "ERROR - StreamSubscription: Error en el stream de entregas: $error",
              _logPrefix);
          await actions.debugLog(
              "ERROR - StreamSubscription Stack: $stackTrace", _logPrefix);
          // Podrías querer actualizar el estado aquí para mostrar un mensaje de error en la UI
          // _setEmptyStream(); // O mostrar un estado de error
        }); // Fin de handleError
      }); // Fin de setState

      // Log después de que setState ha sido llamado (la suscripción se ha iniciado)
      await actions.debugLog(
          'initializeStream: Suscripción al stream configurada.', _logPrefix);
    } else {
      // Log si el widget fue desmontado antes de poder llamar a setState
      await actions.debugLog(
          'WARN (_initializeStream): Widget no montado al intentar suscribir al stream.',
          _logPrefix);
    }
  }

  // Función para establecer un stream vacío (útil en errores o validaciones fallidas)
  void _setEmptyStream() {
    if (mounted) {
      print("$_logPrefix setEmptyStream: Configurando stream a vacío.");
      // Actualiza el estado con un stream que emite una lista vacía inmediatamente
      setState(() {
        _deliveriesStream = Stream.value([]);
      });
    } else {
      // Log si el widget ya no está montado
      print(
          "$_logPrefix setEmptyStream: Widget no montado al intentar setear stream vacío.");
    }
  }

  // --- Construcción de la Interfaz de Usuario (UI) ---
  @override
  Widget build(BuildContext context) {
    // El método build es síncrono, las llamadas a actions.debugLog son fire-and-forget
    return Container(
      width: widget.width,
      height: widget.height,
      // StreamBuilder escucha los cambios en _deliveriesStream y reconstruye la UI
      child: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
        stream: _deliveriesStream, // El stream que configuramos
        builder: (context, snapshot) {
          // 1. Manejo de Estados del Stream
          // Mientras espera el primer dato Y no tenemos datos previos Y el stream no es nulo
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData &&
              _deliveriesStream != null) {
            actions.debugLog(
                'build: Stream esperando datos iniciales...', _logPrefix);
            // Muestra un indicador de carga mientras se conecta y recibe datos
            return const Center(child: CircularProgressIndicator());
          }
          // Si el stream reporta un error
          if (snapshot.hasError) {
            actions.debugLog(
                'ERROR - build: Stream reportó error: ${snapshot.error}',
                _logPrefix);
            if (snapshot.stackTrace != null) {
              actions.debugLog(
                  'ERROR - build Stack: ${snapshot.stackTrace}', _logPrefix);
            }
            // Muestra un mensaje de error
            return Center(
                child: Text('Error al cargar entregas: ${snapshot.error}'));
          }
          // Si el stream aún no se ha inicializado (es nulo)
          if (!snapshot.hasData && _deliveriesStream == null) {
            actions.debugLog(
                'build: Stream es nulo (probablemente inicializando o error previo).',
                _logPrefix);
            // Muestra un mensaje inicial o de espera
            return const Center(child: Text('Iniciando búsqueda...'));
          }
          // Si el stream está activo pero no ha emitido datos (o emitió lista vacía)
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            actions.debugLog(
                'build: Stream activo pero sin datos (o lista vacía).',
                _logPrefix);
            // Muestra un mensaje indicando que no hay resultados
            return const Center(
                child: Text('No hay entregas cercanas disponibles.'));
          }

          // 2. Procesamiento de Datos Recibidos del Stream
          // Tenemos datos (una lista de DocumentSnapshot)
          final List<DocumentSnapshot<Map<String, dynamic>>> documentsInRadius =
              snapshot.data!;
          actions.debugLog(
              'build: Stream recibió ${documentsInRadius.length} documentos dentro del radio.',
              _logPrefix);

          // Lista para almacenar los registros DeliveriesRecord válidos y sus distancias
          final List<Map<String, dynamic>> deliveriesForSort = [];

          // Itera sobre los documentos encontrados por la geoquery
          // Este bucle es síncrono
          for (final docSnapshot in documentsInRadius) {
            final data = docSnapshot.data(); // Obtiene los datos del documento
            final docId = docSnapshot.id; // Obtiene el ID del documento

            if (data != null) {
              // --- Filtrado Adicional (más allá de la cercanía) ---
              final status = data['status'] as String?; // Obtiene el estado
              final driverRef =
                  data['driverRef']; // Verifica si ya tiene conductor asignado

              // Queremos solo entregas pendientes de asignación
              if (status == 'pending_assignment' && driverRef == null) {
                actions.debugLog(
                    'build: -> Doc [$docId] CUMPLE filtro (status=pending_assignment, driverRef=null).',
                    _logPrefix);
                try {
                  // Intenta convertir el DocumentSnapshot a un DeliveriesRecord
                  // ¡ASEGÚRATE QUE TU DeliveriesRecord.fromSnapshot esté actualizado y maneje errores!
                  final DeliveriesRecord record =
                      DeliveriesRecord.fromSnapshot(docSnapshot);

                  // --- Cálculo de Distancia ---
                  double distanceKm =
                      -1.0; // Valor por defecto si no se puede calcular
                  // Extrae el GeoPoint de origen usando el helper síncrono
                  final GeoPoint? originGeoPoint =
                      _extractOriginZoneGeoPointSync(data);

                  // Si tenemos la ubicación del conductor y la ubicación de origen de la entrega...
                  if (widget.driverLocation != null && originGeoPoint != null) {
                    try {
                      // Calcula la distancia usando geolocator
                      distanceKm = Geolocator.distanceBetween(
                            widget.driverLocation!.latitude,
                            widget.driverLocation!.longitude,
                            originGeoPoint.latitude,
                            originGeoPoint.longitude,
                          ) /
                          1000.0; // Convierte metros a kilómetros
                      // actions.debugLog('build:    -> [$docId] Distancia calculada: ${distanceKm.toStringAsFixed(3)} km', _logPrefix); // Log opcional
                    } catch (e) {
                      // Log si falla el cálculo de distancia
                      actions.debugLog(
                          'build:    -> [$docId] ERROR calculando distancia: $e',
                          _logPrefix);
                    }
                  } else {
                    // Log si falta alguna de las ubicaciones para calcular la distancia
                    actions.debugLog(
                        'build:    -> [$docId] WARN: No se pudo calcular distancia (falta driverLocation o originGeoPoint).',
                        _logPrefix);
                  }

                  // Añade el registro y su distancia calculada a la lista para ordenar
                  deliveriesForSort
                      .add({'record': record, 'distanceKm': distanceKm});
                } catch (e, stackTrace) {
                  // Captura errores durante la creación del DeliveriesRecord
                  actions.debugLog(
                      'ERROR - build: Fallo creando DeliveriesRecord desde snapshot [$docId]: $e',
                      _logPrefix);
                  actions.debugLog('Stack: $stackTrace', _logPrefix);
                }
              } else {
                // Log si el documento no pasa el filtro de estado/driverRef
                actions.debugLog(
                    'build: -> Doc [$docId] OMITIDO por filtro (status: $status, driverRef: $driverRef).',
                    _logPrefix);
              } // Fin del if de filtrado
            } else {
              // Log si un documento dentro del radio tiene datos nulos (raro pero posible)
              actions.debugLog(
                  'WARN - build: Documento [$docId] encontrado en radio pero con datos nulos.',
                  _logPrefix);
            }
          } // Fin del bucle for

          // 3. Ordenar las Entregas por Distancia
          actions.debugLog(
              'build: Ordenando ${deliveriesForSort.length} entregas filtradas por distancia...',
              _logPrefix);
          deliveriesForSort.sort((a, b) {
            // Obtiene las distancias (o -1.0 si no se calcularon)
            final double distA = a['distanceKm'] as double? ?? -1.0;
            final double distB = b['distanceKm'] as double? ?? -1.0;
            // Lógica de comparación para manejar distancias no calculadas (-1.0)
            if (distA < 0 && distB < 0)
              return 0; // Ambas sin distancia, mantener orden relativo
            if (distA < 0) return 1; // Poner las sin distancia al final
            if (distB < 0) return -1; // Poner las sin distancia al final
            // Comparar numéricamente las distancias válidas
            return distA
                .compareTo(distB); // Orden ascendente (más cercano primero)
          });

          // 4. Preparar la Lista Final de Registros para el Widget Hijo
          final List<DeliveriesRecord> validDeliveries = deliveriesForSort
              .map((item) => item['record'] as DeliveriesRecord)
              .toList();
          actions.debugLog(
              'build: ${validDeliveries.length} entregas listas y ordenadas para mostrar.',
              _logPrefix);

          // 5. Mostrar el Resultado en el Widget Hijo (ListWidget)
          if (validDeliveries.isEmpty) {
            // Si después de filtrar y procesar no queda ninguna entrega válida
            actions.debugLog(
                'build: No hay entregas válidas después del filtro y procesamiento.',
                _logPrefix);
            return const Center(
                child: Text('No hay entregas disponibles que coincidan.'));
          }

          // Pasa la lista ordenada de DeliveriesRecord al widget componente que las mostrará
          actions.debugLog(
              'build: Pasando ${validDeliveries.length} entregas al componente ListWidget.',
              _logPrefix);
          // ¡ASEGÚRATE DE QUE ESTA RUTA Y EL NOMBRE DEL WIDGET SEAN CORRECTOS!
          // ¡Y QUE ListWidget ESPERE UN PARÁMETRO `deliveries` de tipo List<DeliveriesRecord>!
          return custom_deliveries_component.ListWidget(
            deliveries: validDeliveries,
            // Puedes pasar más parámetros a tu ListWidget si es necesario
          );
        },
      ),
    );
  }

  // --- Helper SÍNCRONO para validar LatLng ---
  // No necesita log avanzado porque es síncrono y simple
  bool _isValidLatLng(LatLng? location) {
    if (location == null) return false;
    final lat = location.latitude;
    final lon = location.longitude;
    // Comprueba NaN (Not a Number) e Infinitos
    if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite)
      return false;
    // Comprueba rangos válidos de latitud y longitud
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
    // Si pasa todas las validaciones, es válido
    return true;
  }
}
