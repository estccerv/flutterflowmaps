const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Asegúrate de que admin.initializeApp() se llame en otro lugar si es necesario,
// o si Firebase/FlutterFlow lo gestiona automáticamente, no lo llames aquí.
// admin.initializeApp();

// --- Constantes para Emojis y Estado ---
const EMOJI = {
  START: "🚀",
  END_SUCCESS: "🏁",
  END_ERROR: "💥",
  AUTH_OK: "🔒",
  AUTH_FAIL: "🔑",
  INPUT_RECEIVED: "📥",
  INPUT_VALIDATED: "✅",
  INPUT_WARN: "❓",
  INPUT_FAIL: "❌",
  ORDER_FETCH: "🔎📦",
  ORDER_OK: "📦✅",
  ORDER_FAIL: "📦❌",
  DELIVERY_CREATE: "🚚💨",
  DELIVERY_OK: "🚚✅",
  DRIVER_CHECK_START: "🧑‍🚒🔍",
  DRIVER_FETCH: "📄➡️",
  DRIVER_PASS: "👍",
  DRIVER_SKIP: "👎",
  DRIVER_WARN: "🧑‍🚒⚠️",
  DRIVER_CHECK_END: "📊",
  NOTIF_PREPARE: "🔔🔧",
  NOTIF_SEND: "🔔➡️",
  NOTIF_OK: "🔔✅",
  NOTIF_SKIP: "🔕",
  ORDER_UPDATE: "📝🔄",
  ORDER_UPDATE_OK: "📝✅",
  ORDER_UPDATE_WARN: "📝⚠️",
  ERROR: "🔥",
  WARN: "⚠️", // Warning general
};

exports.createDeliveriesNotification =
  functions// .region('your-region') // Opcional: Especifica tu región si es necesario
  // .runWith({ memory: '256MB', timeoutSeconds: 60 }) // Opcional: Ajusta recursos
  .https
    .onCall(async (data, context) => {
      const db = admin.firestore();
      const FieldValue = admin.firestore.FieldValue;
      const executionId = context.eventId || `manual-${Date.now()}`; // Útil para trazar ejecuciones únicas

      // --- 1. Autenticación y Parámetros Iniciales ---
      console.log(
        `${EMOJI.START} [${executionId}] Inicio Ejecución createDeliveriesNotification.`,
      );

      if (!context.auth) {
        console.error(
          `${EMOJI.AUTH_FAIL} [${executionId}] Autenticación requerida.`,
        );
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Autenticación requerida.",
        );
      }
      const callingUid = context.auth.uid;
      console.log(
        `${EMOJI.AUTH_OK} [${executionId}] Usuario autenticado: ${callingUid}`,
      );

      // --- 2. Extracción y Validación de Parámetros ---
      const orderId = data.orderUid;
      const driverIdsToNotify = data.driversUds; // Array de IDs de DOCUMENTOS /drivers
      const notificationTitle = data.title || "Oportunidad";
      const notificationText =
        data.text || "Nueva oportunidad de entrega a domicilio";
      const targetPage = data.pageName || "AcceptOpportunityPage"; // Página destino por defecto
      const targetParameterName = data.paramName || "deliveryRef"; // Nombre del parámetro esperado (default: deliveryRef)

      console.log(
        `${EMOJI.INPUT_RECEIVED} [${executionId}] Datos Recibidos: orderId=${orderId}, drivers=${JSON.stringify(driverIdsToNotify)}, title=${data.title}, text=${data.text}, pageName=${data.pageName}, paramName=${data.paramName}`,
      );

      // Validación de parámetros obligatorios (con logs claros)
      let inputValid = true;
      if (!orderId || typeof orderId !== "string") {
        console.error(
          `${EMOJI.INPUT_FAIL} [${executionId}] Error Entrada: 'orderUid' (orderId) inválido.`,
        );
        inputValid = false;
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'orderUid' es requerido y debe ser un string.",
        );
      }

      // Usar orderId en logs de aquí en adelante para mejor contexto
      const logContext = `[Order: ${orderId}]`;

      if (!Array.isArray(driverIdsToNotify)) {
        console.error(
          `${EMOJI.INPUT_FAIL} ${logContext} Error Entrada: 'driversUds' debe ser un array.`,
        );
        inputValid = false;
        throw new functions.https.HttpsError(
          "invalid-argument",
          "'driversUds' debe ser un array.",
        );
      }
      if (data.title && typeof data.title !== "string") {
        console.warn(
          `${EMOJI.INPUT_WARN} ${logContext} 'title' no es string. Usando default: '${notificationTitle}'.`,
        );
      }
      if (data.text && typeof data.text !== "string") {
        console.warn(
          `${EMOJI.INPUT_WARN} ${logContext} 'text' no es string. Usando default: '${notificationText}'.`,
        );
      }
      if (data.pageName && typeof data.pageName !== "string") {
        console.warn(
          `${EMOJI.INPUT_WARN} ${logContext} 'pageName' no es string. Usando default: '${targetPage}'.`,
        );
      }
      if (data.paramName && typeof data.paramName !== "string") {
        console.warn(
          `${EMOJI.INPUT_WARN} ${logContext} 'paramName' no es string. Usando default: '${targetParameterName}'.`,
        );
      }

      if (!inputValid) {
        // Si hubo errores que no lanzaron excepción antes, lanzarla ahora
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Parámetros de entrada inválidos.",
        );
      }
      console.log(
        `${EMOJI.INPUT_VALIDATED} ${logContext} Parámetros OK. A usar: title='${notificationTitle}', text='${notificationText}', page='${targetPage}', param='${targetParameterName}', drivers=${driverIdsToNotify.length}`,
      );

      const warnings = []; // Para acumular advertencias no críticas

      try {
        // --- 3. Obtener y Validar Orden ---
        console.log(
          `${EMOJI.ORDER_FETCH} ${logContext} Obteniendo datos de la orden...`,
        );
        const orderRef = db.collection("orders").doc(orderId);
        const orderSnap = await orderRef.get();

        if (!orderSnap.exists) {
          console.error(
            `${EMOJI.ORDER_FAIL} ${logContext} Orden no encontrada.`,
          );
          throw new functions.https.HttpsError(
            "not-found",
            `Orden ${orderId} no encontrada.`,
          );
        }
        const orderData = orderSnap.data();
        console.log(
          `${EMOJI.ORDER_OK} ${logContext} Datos de la orden obtenidos.`,
        );

        // Validación simplificada (asegurarse de que los objetos/refs necesarios existen)
        const { customerRef, businessRef, customerZone, businessZone } =
          orderData;
        let validationError = false;
        if (!(customerRef instanceof admin.firestore.DocumentReference)) {
          console.error(
            `${EMOJI.ORDER_FAIL} ${logContext} Falta/inválido customerRef.`,
          );
          validationError = true;
        }
        if (!(businessRef instanceof admin.firestore.DocumentReference)) {
          console.error(
            `${EMOJI.ORDER_FAIL} ${logContext} Falta/inválido businessRef.`,
          );
          validationError = true;
        }
        if (!customerZone?.geopoint || !customerZone?.geohash) {
          console.error(
            `${EMOJI.ORDER_FAIL} ${logContext} Falta/inválido customerZone.`,
          );
          validationError = true;
        }
        if (!businessZone?.geopoint || !businessZone?.geohash) {
          console.error(
            `${EMOJI.ORDER_FAIL} ${logContext} Falta/inválido businessZone.`,
          );
          validationError = true;
        }

        if (validationError) {
          console.error(
            `${EMOJI.ORDER_FAIL} ${logContext} Falló validación de datos críticos en la orden.`,
          );
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Datos inválidos/faltantes en la orden.",
          );
        }
        console.log(
          `${EMOJI.ORDER_OK} ${logContext} Datos de la orden validados OK.`,
        );

        // --- 4. Crear Documento 'deliveries' ---
        console.log(
          `${EMOJI.DELIVERY_CREATE} ${logContext} Creando NUEVO documento 'deliveries'...`,
        );
        const deliveryData = {
          status: "pending_assignment",
          createdAt: FieldValue.serverTimestamp(),
          orderRef: orderRef,
          originZone: businessZone,
          destinationZone: customerZone,
          driverRef: null, // Referencia al /users del driver que acepta
          acceptanceZone: null,
        };
        const newDeliveryRef = await db
          .collection("deliveries")
          .add(deliveryData);
        const newDeliveryId = newDeliveryRef.id;
        const newDeliveryPath = newDeliveryRef.path; // Guardar el path completo (ej: "deliveries/docID")
        console.log(
          `${EMOJI.DELIVERY_OK} ${logContext} Documento 'deliveries' creado: ${newDeliveryPath}`,
        );

        // --- 5. Verificar Conductores (Disponibilidad + Online) ---
        console.log(
          `${EMOJI.DRIVER_CHECK_START} ${logContext} Verificando ${driverIdsToNotify.length} conductores candidatos...`,
        );
        const finalUserRefsToNotify = []; // Almacenará paths 'users/USER_ID'
        const checkedDriverStats = { available: 0, online: 0 };

        if (driverIdsToNotify.length > 0) {
          // 5a: Fetch /drivers docs
          console.log(
            `  ${EMOJI.DRIVER_FETCH} ${logContext} Obteniendo ${driverIdsToNotify.length} docs /drivers...`,
          );
          const driverDocRefs = driverIdsToNotify.map((id) =>
            db.collection("drivers").doc(id),
          );
          const driverDocSnaps = await db.getAll(...driverDocRefs);

          // 5b: Filtrar por isAvailable y obtener userRef
          const availableDriverUserRefs = [];
          const availableDriverUserRefMap = new Map(); // Mapea userRef.path -> driverId (para logs)
          console.log(
            `  ${EMOJI.DRIVER_CHECK_START} ${logContext} Filtrando ${driverDocSnaps.length} /drivers por 'isAvailable'...`,
          );
          for (const driverDocSnap of driverDocSnaps) {
            const driverId = driverDocSnap.id;
            if (driverDocSnap.exists) {
              const { isAvailable, userRef } = driverDocSnap.data();
              const userRefIsValid =
                userRef instanceof admin.firestore.DocumentReference;
              if (isAvailable === true && userRefIsValid) {
                console.log(
                  `    ${EMOJI.DRIVER_PASS} ${logContext} Driver ${driverId} (User: ${userRef.id}) - Disponible.`,
                );
                availableDriverUserRefs.push(userRef);
                availableDriverUserRefMap.set(userRef.path, driverId);
                checkedDriverStats.available++;
              } else {
                console.log(
                  `    ${EMOJI.DRIVER_SKIP} ${logContext} Driver ${driverId} OMITIDO (Available=${isAvailable}, UserRef=${userRef?.path || "N/A"}, Valid=${userRefIsValid}).`,
                );
              }
            } else {
              const warnMsg = `Driver ID ${driverId} no encontrado en /drivers.`;
              console.warn(`    ${EMOJI.DRIVER_WARN} ${logContext} ${warnMsg}`);
              warnings.push(warnMsg);
            }
          }

          // 5c: Fetch /users docs de los drivers disponibles
          if (availableDriverUserRefs.length > 0) {
            console.log(
              `  ${EMOJI.DRIVER_FETCH} ${logContext} Obteniendo ${availableDriverUserRefs.length} docs /users correspondientes...`,
            );
            const userDocSnaps = await db.getAll(...availableDriverUserRefs);

            // 5d: Filtrar por isOnline
            console.log(
              `  ${EMOJI.DRIVER_CHECK_START} ${logContext} Filtrando ${userDocSnaps.length} /users por 'isOnline'...`,
            );
            for (const userDocSnap of userDocSnaps) {
              const userId = userDocSnap.id;
              const userRefPath = userDocSnap.ref.path; // Path como 'users/USER_ID'
              const correspondingDriverId =
                availableDriverUserRefMap.get(userRefPath) || "??"; // Recuperar ID del driver para logs
              if (userDocSnap.exists) {
                const { isOnline } = userDocSnap.data();
                if (isOnline === true) {
                  console.log(
                    `    ${EMOJI.DRIVER_PASS} ${logContext} User ${userId} (Driver ${correspondingDriverId}) - Online. Añadido.`,
                  );
                  finalUserRefsToNotify.push(userRefPath); // Guardar path 'users/USER_ID' para la notificación
                  checkedDriverStats.online++;
                } else {
                  console.log(
                    `    ${EMOJI.DRIVER_SKIP} ${logContext} User ${userId} (Driver ${correspondingDriverId}) OMITIDO (Online=${isOnline}).`,
                  );
                }
              } else {
                const warnMsg = `User ID ${userId} (Driver ${correspondingDriverId}) no encontrado en /users.`;
                console.warn(
                  `    ${EMOJI.DRIVER_WARN} ${logContext} ${warnMsg}`,
                );
                warnings.push(warnMsg);
              }
            }
          } else {
            console.log(
              `  ${EMOJI.DRIVER_SKIP} ${logContext} Ningún driver de la lista inicial está 'isAvailable' o tiene userRef válido.`,
            );
          }
        } else {
          console.log(
            `  ${EMOJI.DRIVER_SKIP} ${logContext} No hay IDs de /drivers candidatos proporcionados.`,
          );
        }
        console.log(
          `${EMOJI.DRIVER_CHECK_END} ${logContext} Verificación completa. Iniciales: ${driverIdsToNotify.length}, Disponibles: ${checkedDriverStats.available}, Online: ${checkedDriverStats.online}. A notificar: ${finalUserRefsToNotify.length}`,
        );

        // --- 6. Crear Documento de Notificación Push ---
        let notificationStatus = "no_drivers_to_notify";
        let notificationMessage = `Oportunidad ${newDeliveryId} creada, pero no hay conductores disponibles/online para notificar.`;
        let createdPushDocId = null;

        if (finalUserRefsToNotify.length > 0) {
          console.log(
            `${EMOJI.NOTIF_PREPARE} ${logContext} Preparando notificación push para ${finalUserRefsToNotify.length} usuarios...`,
          );

          // Crear objeto para parameter_data
          const parameterData = {};
          // Usar el nombre de parámetro dinámico (o default 'deliveryRef')
          // y asignar el PATH completo del documento de entrega como valor
          parameterData[targetParameterName] = newDeliveryPath;

          const userRefsString = finalUserRefsToNotify.join(","); // Convertir array de paths a string CSV
          const notificationPayload = {
            notification_title: notificationTitle,
            notification_text: notificationText,
            notification_sound: "default", // Sonido predeterminado
            parameter_data: JSON.stringify(parameterData), // Convertir objeto a JSON string
            target_audience: "Users",
            initial_page_name: targetPage, // Página a abrir
            user_refs: userRefsString, // String de paths 'users/USER_ID' separados por comas
            timestamp: FieldValue.serverTimestamp(),
          };

          console.log(
            `  ${EMOJI.NOTIF_SEND} ${logContext} Payload Notificación: ${JSON.stringify(notificationPayload)}`,
          ); // Log completo del payload
          console.log(
            `  ${EMOJI.NOTIF_SEND} ${logContext} Creando documento en 'ff_push_notifications'...`,
          );
          const pushNotifRef = await db
            .collection("ff_push_notifications")
            .add(notificationPayload);
          createdPushDocId = pushNotifRef.id;
          console.log(
            `${EMOJI.NOTIF_OK} ${logContext} Notificación push creada (${createdPushDocId}) para entrega ${newDeliveryId}.`,
          );

          notificationStatus = "success";
          notificationMessage = `Notificación enviada a ${finalUserRefsToNotify.length} repartidores para la entrega ${newDeliveryId}.`;
        } else {
          console.log(
            `${EMOJI.NOTIF_SKIP} ${logContext} No hay usuarios finales a notificar. No se crea documento ff_push_notifications.`,
          );
        }

        // --- 7. Actualizar Orden con Referencia a la Entrega (Opcional pero recomendado) ---
        try {
          console.log(
            `${EMOJI.ORDER_UPDATE} ${logContext} Actualizando orden ${orderId} con deliveryRef ${newDeliveryRef.path}...`,
          );
          // Guardar la referencia al documento, no solo el path
          await orderRef.update({ deliveryRef: newDeliveryRef });
          console.log(
            `${EMOJI.ORDER_UPDATE_OK} ${logContext} Orden actualizada correctamente.`,
          );
        } catch (updateError) {
          const warnMsg = `No se pudo actualizar la orden ${orderId} con la ref a entrega ${newDeliveryId}. Error: ${updateError.message}`;
          console.error(`${EMOJI.ORDER_UPDATE_WARN} ${logContext} ${warnMsg}`);
          warnings.push(warnMsg);
          // No lanzar error fatal por esto, pero registrarlo.
        }

        // --- 8. Devolver Resultado ---
        const result = {
          status: notificationStatus,
          message: notificationMessage,
          orderId: orderId,
          deliveryId: newDeliveryId,
          deliveryPath: newDeliveryPath, // Path del documento creado
          initialCandidatesCount: driverIdsToNotify.length,
          availableDriversCount: checkedDriverStats.available,
          onlineDriversCount: checkedDriverStats.online, // Conteo de drivers que estaban online
          notifiedUsersCount: finalUserRefsToNotify.length, // Conteo final de usuarios notificados
          pushNotificationDocId: createdPushDocId, // ID del doc en ff_push_notifications (o null)
          warnings: warnings, // Lista de advertencias no críticas
        };
        console.log(
          `${EMOJI.END_SUCCESS} ${logContext} Ejecución finalizada (${notificationStatus}). Resultado: ${JSON.stringify(result)}`,
        );
        return result;
      } catch (error) {
        // --- Manejo Centralizado de Errores ---
        const currentOrderId = orderId || "N/A"; // Usar el orderId si está disponible
        const errorContext = `[Order: ${currentOrderId}]`; // Contexto para el log de error

        console.error(
          `${EMOJI.ERROR} ${errorContext} ***** ERROR INESPERADO DURANTE LA EJECUCIÓN *****`,
        );
        console.error(`  Mensaje: ${error.message}`);
        if (error.stack) {
          console.error(`  Stack Trace:\n ${error.stack}`);
        }

        // Registrar advertencias acumuladas si existen, incluso en caso de error
        if (warnings.length > 0) {
          console.warn(
            `${EMOJI.WARN} ${errorContext} Advertencias acumuladas antes del error:`,
            warnings,
          );
        }

        if (error instanceof functions.https.HttpsError) {
          // Si ya es un HttpsError (lanzado por nosotros), relanzarlo
          console.error(
            `${EMOJI.ERROR} ${errorContext} Relanzando HttpsError (Código: ${error.code}, Mensaje: ${error.message})`,
          );
          const details = {
            ...(error.details || {}),
            orderId: currentOrderId,
            executionId: executionId,
            accumulatedWarnings: warnings,
          };
          throw new functions.https.HttpsError(
            error.code,
            error.message,
            details,
          );
        } else {
          // Si es un error inesperado (Firestore, etc.), envolverlo en un HttpsError 'internal'
          console.error(
            `${EMOJI.ERROR} ${errorContext} Envolviendo error inesperado en HttpsError 'internal'.`,
          );
          throw new functions.https.HttpsError(
            "internal",
            "Ocurrió un error interno procesando la solicitud.",
            {
              originalError: error.message,
              orderId: currentOrderId,
              executionId: executionId,
              accumulatedWarnings: warnings,
            },
          );
        }
        // Nota: El 'throw' anterior detendrá la ejecución. El log final de error es más bien simbólico aquí.
        // console.log(`${EMOJI.END_ERROR} ${errorContext} Ejecución fallida.`);
      } // Fin try-catch
    }); // Fin https.onCall

/*
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Asegúrate de que admin.initializeApp() se llame en otro lugar de tu proyecto
// o si es necesario aquí, pero fuera de la exportación de la función.
// Si Firebase/FlutterFlow lo gestiona, no lo llames aquí.
// admin.initializeApp(); // Descomentar solo si es absolutamente necesario aquí

exports.createDeliveriesNotification = functions
  // .region('tu-region') // Opcional: Especifica la región
  // .runWith({ memory: '256MB', timeoutSeconds: 60 }) // Opcional: Ajusta recursos
  .https.onCall(async (data, context) => {
    // --- Inicialización de Firestore ---
    const db = admin.firestore();
    const FieldValue = admin.firestore.FieldValue;

    const logPrefix = `[createDeliveriesNotification vNewDelivery]`; // Prefijo para identificar esta versión
    const executionId = context.eventId || `manual-${Date.now()}`;
    console.log(`${logPrefix}[${executionId}] ========= Inicio Ejecución Función =========`);

    // --- 1. Autenticación ---
    if (!context.auth) {
      console.error(`${logPrefix}[${executionId}] Error Autenticación: No autenticado.`);
      throw new functions.https.HttpsError('unauthenticated', 'Autenticación requerida.');
    }
    const callingUid = context.auth.uid;
    console.log(`${logPrefix}[${executionId}] Usuario autenticado: ${callingUid}`);

    // --- 2. Extracción y Validación de Parámetros de Entrada ---
    const orderId = data.orderUid; // ID de la Orden
    const driverIdsToNotify = data.driversUds; // Array de IDs de DOCUMENTOS /drivers
    const notificationTitle = data.title || 'Oportunidad';
    const notificationText = data.text || 'Nueva oportunidad de entrega a domicilio';
    const targetPage = data.pageName || 'AcceptOpportunityPage'; // ¡Verificar este nombre de página en tu App!
    // Los parámetros maxRadiusKm y businessLocation no se usan en esta lógica de notificación
    // pero podrían usarse si la SELECCIÓN de driversUds se hiciera aquí en lugar de pasarla.
    console.log(`${logPrefix}[${executionId}] Datos Recibidos: orderId=${orderId}, driverIdsToNotify=${JSON.stringify(driverIdsToNotify)}, title=${data.title}, text=${data.text}, pageName=${data.pageName}`);
    console.log(`${logPrefix}[${executionId}] Valores a Usar: title='${notificationTitle}', text='${notificationText}', targetPage='${targetPage}'`);

    // Validación de parámetros obligatorios
    if (!orderId || typeof orderId !== 'string') {
      console.error(`${logPrefix}[${executionId}] Error Entrada: 'orderUid' (orderId) inválido.`);
      throw new functions.https.HttpsError('invalid-argument', "'orderUid' es requerido y debe ser un string.");
    }
    if (!Array.isArray(driverIdsToNotify)) {
      console.error(`${logPrefix}[${executionId}] Error Entrada: 'driversUds' (driverIdsToNotify) debe ser un array. Recibido:`, driverIdsToNotify);
      throw new functions.https.HttpsError('invalid-argument', "'driversUds' debe ser un array de IDs /drivers.");
    }
     // Validación opcional tipos de parámetros de notificación
    if (data.title && typeof data.title !== 'string') {
       console.warn(`${logPrefix}[${executionId}] Advertencia Entrada: 'title' recibido pero no es string. Se usará default.`);
    }
     if (data.text && typeof data.text !== 'string') {
       console.warn(`${logPrefix}[${executionId}] Advertencia Entrada: 'text' recibido pero no es string. Se usará default.`);
    }
     if (data.pageName && typeof data.pageName !== 'string') {
       console.warn(`${logPrefix}[${executionId}] Advertencia Entrada: 'pageName' recibido pero no es string. Se usará default.`);
    }

    const specificLogPrefix = `${logPrefix}[Order: ${orderId}][${executionId}]`;
    console.log(`${specificLogPrefix} Iniciando procesamiento. Candidatos /drivers iniciales: ${driverIdsToNotify.length}`);
    const warnings = [];

    try {
      // --- 3. Obtener y Validar Datos de la Orden ---
      console.log(`${specificLogPrefix} Paso 3: Obteniendo y validando datos de la orden...`);
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        console.error(`${specificLogPrefix} Error: Orden no encontrada.`);
        throw new functions.https.HttpsError('not-found', `Orden ${orderId} no encontrada.`);
      }
      const orderData = orderSnap.data();
      console.log(`${specificLogPrefix} Datos de la orden obtenidos.`);

      // Validación de campos necesarios de la orden para crear la entrega y notificar
      const { business: businessInfo, customerRef, businessRef, customerZone, businessZone } = orderData;
      let validationError = false;
      // Nota: No necesitamos businessInfo.name para la entrega en sí, pero puede ser útil para el texto de notificación si no se pasa 'text'.
      // if (!businessInfo?.name) { console.error(`${specificLogPrefix} Error Validación Orden: Falta business.name.`); validationError = true; } // Opcional si el texto se pasa siempre
      if (!(customerRef instanceof admin.firestore.DocumentReference)) { console.error(`${specificLogPrefix} Error Validación Orden: Falta o inválido customerRef.`); validationError = true; }
      if (!(businessRef instanceof admin.firestore.DocumentReference)) { console.error(`${specificLogPrefix} Error Validación Orden: Falta o inválido businessRef.`); validationError = true; }
      // Validar estructura de Zone (geohash y geopoint)
      if (!customerZone?.geopoint?.latitude || !customerZone?.geopoint?.longitude || !customerZone?.geohash) { console.error(`${specificLogPrefix} Error Validación Orden: Falta o inválido customerZone.`); validationError = true; }
      if (!businessZone?.geopoint?.latitude || !businessZone?.geopoint?.longitude || !businessZone?.geohash) { console.error(`${specificLogPrefix} Error Validación Orden: Falta o inválido businessZone.`); validationError = true; }

      if (validationError) {
        console.error(`${specificLogPrefix} Falló la validación de datos requeridos en la orden.`);
        throw new functions.https.HttpsError('failed-precondition', 'Datos inválidos o faltantes en la orden (customerRef, businessRef, customerZone, businessZone).');
      }
      console.log(`${specificLogPrefix} Datos de la orden validados OK.`);

      // --- 4. Crear SIEMPRE un Nuevo Documento 'deliveries' ---
      console.log(`${specificLogPrefix} Paso 4: Creando NUEVO documento 'deliveries'...`);
      const deliveryData = {
        status: 'pending_assignment', // Estado inicial
        createdAt: FieldValue.serverTimestamp(), // Hora de creación
        orderRef: orderRef, // Referencia a la orden
        originZone: businessZone, // Zona de origen (negocio)
        destinationZone: customerZone, // Zona de destino (cliente)
        // Campos adicionales que podrías querer inicializar como null o default
        driverRef: null, // Se asignará cuando un conductor acepte
        acceptanceZone: null, // Se registrará cuando un conductor acepte (opcional)
        // Puedes añadir otros campos según necesites
      };
      const newDeliveryRef = await db.collection('deliveries').add(deliveryData);
      const newDeliveryId = newDeliveryRef.id;
      console.log(`${specificLogPrefix} Nuevo documento 'deliveries' creado: ${newDeliveryId}`);

      // --- 5. Verificar Conductores (Disponibilidad + Online) ---
      // (Esta sección no cambia respecto al código base, sigue filtrando los IDs proporcionados)
      console.log(`${specificLogPrefix} Paso 5: Verificando estado de conductores...`);
      const finalUserRefsToNotify = [];
      const availableCheckedDriverIds = []; // Para logs/stats
      const onlineCheckedUserPaths = [];   // Para logs/stats

      if (driverIdsToNotify.length > 0) {
        // 5a: Fetch /drivers docs
        console.log(`${specificLogPrefix} 5a: Obteniendo ${driverIdsToNotify.length} documentos /drivers...`);
        const driverDocRefs = driverIdsToNotify.map((id) => db.collection('drivers').doc(id));
        const driverDocSnaps = await db.getAll(...driverDocRefs);

        // 5b: Filter by isAvailable, collect userRefs
        const availableDriverUserRefs = [];
        const availableDriverUserRefMap = new Map(); // Para mapear userRef.path -> driverId (útil para logs)
        console.log(`${specificLogPrefix} 5b: Filtrando ${driverDocSnaps.length} /drivers por isAvailable=true y userRef válido...`);
        for (const driverDocSnap of driverDocSnaps) {
           const driverId = driverDocSnap.id;
           if (driverDocSnap.exists) {
             const { isAvailable, userRef } = driverDocSnap.data();
             const userRefIsValid = userRef instanceof admin.firestore.DocumentReference;
             if (isAvailable === true && userRefIsValid) {
               console.log(`${specificLogPrefix}   -> Driver ${driverId} OK (isAvailable=true, userRef=${userRef.path}).`);
               availableDriverUserRefs.push(userRef);
               availableDriverUserRefMap.set(userRef.path, driverId);
               availableCheckedDriverIds.push(driverId);
             } else {
               console.log(`${specificLogPrefix}   -> Driver ${driverId} OMITIDO (isAvailable=${isAvailable}, userRef=${userRef?.path || 'N/A'}, userRefIsValid=${userRefIsValid}).`);
             }
           } else {
             const warnMsg = `Driver ID ${driverId} no encontrado en /drivers.`;
             console.warn(`${specificLogPrefix}   -> ADVERTENCIA: ${warnMsg}`);
             warnings.push(warnMsg);
           }
        }

        // 5c: Fetch /users docs
        if (availableDriverUserRefs.length > 0) {
          console.log(`${specificLogPrefix} 5c: Obteniendo ${availableDriverUserRefs.length} documentos /users correspondientes...`);
          const userDocSnaps = await db.getAll(...availableDriverUserRefs);

          // 5d: Filter by isOnline
          console.log(`${specificLogPrefix} 5d: Filtrando ${userDocSnaps.length} /users por isOnline=true...`);
          for (const userDocSnap of userDocSnaps) {
             const userId = userDocSnap.id;
             const userRefPath = userDocSnap.ref.path; // Path como 'users/USER_ID'
             const correspondingDriverId = availableDriverUserRefMap.get(userRefPath) || 'Desconocido';
             if (userDocSnap.exists) {
               const { isOnline } = userDocSnap.data();
               if (isOnline === true) {
                 console.log(`${specificLogPrefix}   -> User ${userId} (Driver ${correspondingDriverId}) OK (isOnline=true). Añadiendo a notificación.`);
                 finalUserRefsToNotify.push(userRefPath); // Guardamos el path 'users/USER_ID'
                 onlineCheckedUserPaths.push(userRefPath);
               } else {
                 console.log(`${specificLogPrefix}   -> User ${userId} (Driver ${correspondingDriverId}) OMITIDO (isOnline=${isOnline}).`);
               }
             } else {
               const warnMsg = `User ID ${userId} (referenciado por Driver ${correspondingDriverId}) no encontrado en /users.`;
               console.warn(`${specificLogPrefix}   -> ADVERTENCIA: ${warnMsg}`);
               warnings.push(warnMsg);
             }
          }
        } else {
          console.log(`${specificLogPrefix} Ningún driver de la lista inicial está 'isAvailable' o tiene userRef válido.`);
        }
      } else {
        console.log(`${specificLogPrefix} No hay IDs /drivers candidatos proporcionados en la entrada.`);
      }
      console.log(`${specificLogPrefix} Verificación completada. Usuarios finales a notificar: ${finalUserRefsToNotify.length}`);

      // --- 6. Crear Documento de Notificación Push ---
      console.log(`${specificLogPrefix} Paso 6: Creando documento de notificación push...`);
      let notificationStatus = 'no_drivers_to_notify';
      let notificationMessage = `Oportunidad ${newDeliveryId} creada, pero no hay conductores disponibles y online en la lista para notificar.`;
      let createdPushDocId = null;

      if (finalUserRefsToNotify.length > 0) {
        console.log(`${specificLogPrefix} Preparando payload para 'ff_push_notifications'...`);

        // *** USAR LOS PARÁMETROS (O DEFAULTS) PARA EL PAYLOAD ***
        const userRefsString = finalUserRefsToNotify.join(','); // Convertir array de paths a string CSV
        const notificationPayload = {
          notification_title: notificationTitle,   // Título de la notificación
          notification_text: notificationText,     // Cuerpo de la notificación
          notification_sound: 'default',           // Sonido (puede ser parámetro opcional)
          // --- Dato clave: Pasar el docRed de la NUEVA entrega ---
          parameter_data: JSON.stringify({ deliveryRef: `deliveries/${newDeliveryId}` }),
          target_audience: 'Users',                // Siempre 'Users' al usar user_refs
          initial_page_name: targetPage,           // Página a abrir en la app
          user_refs: userRefsString,               // STRING de paths 'users/USER_ID' separados por comas
          timestamp: FieldValue.serverTimestamp(), // Hora de creación de la notificación
        };
        // ********************************************************

        console.log(`${specificLogPrefix} Payload Notificación: ${JSON.stringify(notificationPayload)}`);
        console.log(`${specificLogPrefix} Creando documento en 'ff_push_notifications'...`);
        const pushNotifRef = await db.collection('ff_push_notifications').add(notificationPayload);
        createdPushDocId = pushNotifRef.id;
        console.log(`${specificLogPrefix} Documento ff_push_notifications creado (${createdPushDocId}) para entrega ${newDeliveryId}.`);

        notificationStatus = 'success';
        notificationMessage = `Notificación enviada a ${finalUserRefsToNotify.length} repartidores para la nueva entrega ${newDeliveryId}.`;
      } else {
        console.log(`${specificLogPrefix} No hay usuarios finales a notificar. No se crea documento ff_push_notifications.`);
      }

       // --- 7. Actualizar Orden con Referencia a la Entrega (Opcional pero recomendado) ---
       // Esto ayuda a vincular la orden directamente con su intento de entrega más reciente.
       try {
           console.log(`${specificLogPrefix} Paso 7 (Opcional): Actualizando orden ${orderId} con deliveryRef ${newDeliveryRef.path}...`);
           await orderRef.update({ deliveryRef: newDeliveryRef });
           console.log(`${specificLogPrefix} Orden actualizada correctamente.`);
       } catch (updateError) {
           const warnMsg = `No se pudo actualizar la orden ${orderId} con la referencia a la nueva entrega ${newDeliveryId}. Error: ${updateError.message}`;
           console.error(`${specificLogPrefix} ADVERTENCIA: ${warnMsg}`);
           warnings.push(warnMsg);
           // No lanzamos error fatal por esto, pero lo registramos.
       }


      // --- 8. Devolver Resultado ---
      console.log(`${specificLogPrefix} ========= Finalizando Ejecución Función (${notificationStatus}) =========`);
      return {
        status: notificationStatus,
        message: notificationMessage,
        orderId: orderId,
        deliveryId: newDeliveryId, // Devuelve el ID de la NUEVA entrega creada
        initialCandidatesCount: driverIdsToNotify.length,
        availableDriversCount: availableCheckedDriverIds.length, // Drivers que pasaron chequeo isAvailable
        notifiedUsersCount: finalUserRefsToNotify.length,   // Users que pasaron chequeo isOnline
        notifiedUserPaths: finalUserRefsToNotify, // Array de 'users/USER_ID' notificados
        pushNotificationDocId: createdPushDocId, // ID del doc en ff_push_notifications (o null)
        warnings: warnings, // Lista de advertencias (docs no encontrados, etc.)
      };

    } catch (error) {
      // --- Manejo Centralizado de Errores ---
      console.error(`${specificLogPrefix} ***** ERROR INESPERADO DURANTE LA EJECUCIÓN *****`);
      console.error(`${specificLogPrefix} Mensaje Error: ${error.message}`);
      if (error.stack) { console.error(`${specificLogPrefix} Stack Trace:\n ${error.stack}`); }

      if (error instanceof functions.https.HttpsError) {
        // Si ya es un HttpsError (lanzado por nosotros), relanzarlo
        console.error(`${specificLogPrefix} Relanzando HttpsError (Código: ${error.code}, Mensaje: ${error.message})`);
        // Añadir contexto al error si es posible
        const details = { ...(error.details || {}), orderId: orderId, executionId: executionId };
        throw new functions.https.HttpsError(error.code, error.message, details);
      } else {
        // Si es un error inesperado (Firestore, etc.), envolverlo en un HttpsError 'internal'
        console.error(`${specificLogPrefix} Envolviendo error inesperado en HttpsError 'internal'.`);
        throw new functions.https.HttpsError(
          'internal',
          'Ocurrió un error interno procesando la solicitud.',
          { originalError: error.message, orderId: orderId, executionId: executionId }
        );
      }
    } // Fin try-catch
  }); // Fin https.onCall


  */

/*
  import { Firestore } from '@google-cloud/firestore';

export default async function createFfNotification({
 id,
 projectId,
 notification_title,
 notification_text,
 notification_image_url,
 notification_sound,
 parameter_data,
 target_audience,
 initial_page_name,
 user_refs
}: NodeInputs) : NodeOutput  {
 // Create the data object using only the specified notification-related parameters
 const data = {
 notification_title: notification_title || "",
 notification_text: notification_text || "",
 notification_image_url: notification_image_url || "",
 notification_sound: notification_sound || "",
 parameter_data: parameter_data || "",
 target_audience: target_audience || "",
 initial_page_name: initial_page_name || "",
 user_refs: user_refs || ""
 };

 // Hardcoded collection name
 const collectionName = 'ff_push_notifications';

 const firestore = new Firestore(projectId && projectId.length > 1 ? {
 projectId: projectId.trim()
 } : undefined);

 if (id) {
 await firestore.collection(collectionName).doc(id).set(data, false );
 return {
 id,
 path: `${collectionName}/${id}`,
 status: 'success!'
 };
 } else {
 const ref = await firestore.collection(collectionName).add(data);
 return {
 id: ref.id,
 path: ref.path,
 status: 'success!'
 };
 }
}

*/
