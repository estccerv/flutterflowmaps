// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async'; // Aunque la lógica es síncrona, mantener Future<void> es estándar en FF

Future debugLog(
  String? message, // Mensaje a registrar
  String? prefix, // Prefijo opcional para identificar el origen del log
) async {
  // Si el mensaje es nulo o vacío, no hacemos nada.
  if (message == null || message.isEmpty) {
    print(
        '[debugLog Action] WARN: Mensaje nulo o vacío recibido. No se registra nada.');
    return;
  }

  // Define un prefijo por defecto si no se proporciona uno.
  final String effectivePrefix =
      (prefix != null && prefix.isNotEmpty) ? prefix : '[Log]';

  // 1. Obtener timestamp formateado
  final timestamp = DateTime.now().toIso8601String().substring(11, 23);

  // 2. Formatear el mensaje final
  final logMessage = '$timestamp $effectivePrefix $message';

  // 3. Imprimir en la consola de depuración (Run/Test mode)
  print(logMessage);

  // 4. Añadir al App State 'debug' (si existe y es una lista)
  try {
    // Accede a FFAppState directamente
    FFAppState().update(() {
      // Verifica si 'debug' es realmente una lista antes de intentar añadir.
      if (FFAppState().debug is List) {
        // Casting seguro después de la comprobación
        // (aunque FF debería generar esto correctamente si el tipo está bien definido)
        var debugList = FFAppState().debug as List;
        // Comprueba si los elementos son String o si permite dynamic
        if (debugList is List<String> || debugList is List<dynamic>) {
          debugList.add(logMessage);
        } else {
          // Si es una lista pero no del tipo correcto
          print(
              '$effectivePrefix WARN: FFAppState().debug es una lista, pero no de String/dynamic. No se pudo añadir log.');
        }
      } else {
        // Si FFAppState().debug no es una lista (o es null)
        print(
            '$effectivePrefix WARN: FFAppState().debug no es una Lista o es null. Asegúrate de que exista y sea List<String> en App State.');
      }
    });
  } catch (e, stackTrace) {
    // Error al intentar actualizar el App State
    print('$effectivePrefix ERROR: Fallo al actualizar FFAppState().debug: $e');
    print('$effectivePrefix StackTrace: $stackTrace');
  }
}
// DO NOT REMOVE OR MODIFY THE CODE BELOW!
// End custom action code

/*
Future debugPrint(
  String? message,
  bool? debug,
  int? limit,
) async {
  try {
    if (message == null || message.trim().isEmpty) return;

    // 1. Imprimir siempre en consola
    print(message);

    // 2. Control de parámetros   
    final shouldDebug = debug ?? true;
    final limitSize = limit ?? -1;

    if (shouldDebug) {
      FFAppState().update(() {
        FFAppState().debug.add(message!);

        if (limitSize > 0 && FFAppState().debug.length > limitSize) {
          final itemsToRemove = FFAppState().debug.length - limitSize;
          FFAppState().debug.removeRange(0, itemsToRemove);
        }
      });
    }
  } catch (error) {
    final errorTrace = StackTrace.current;
    final errorMessage = '''
    ⦿—————[DEBUG PRINT ERROR]—————
    ⦿ Mensaje original: ${message ?? 'null'}
    ⦿ Error: $error
    ⦿ Stack Trace:
    ${errorTrace.toString().split('\n').take(3).join('\n⦿ ')}
    ⦿—————————————————————————————'''
        .replaceAll('    ', ''); // Corrección clave aquí

    print(errorMessage);

    FFAppState().update(() {
      FFAppState().debug.add(errorMessage);
    });
  }
}
*/
