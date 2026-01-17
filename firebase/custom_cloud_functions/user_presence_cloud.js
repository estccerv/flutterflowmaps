const functions = require("firebase-functions");
const admin = require("firebase-admin");
// To avoid deployment errors, do not call admin.initializeApp() in your code

const firestore = admin.firestore();

exports.userPresenceCloud = functions.database
  .ref("/users/{uid}/connections")
  .onWrite(async (change, context) => {
    const connections = change.after.val();
    const userId = context.params.uid;

    // 1. Calcular número de conexiones
    const isConnectionsObject =
      connections !== null && typeof connections === "object";
    const numConnections = isConnectionsObject
      ? Object.keys(connections).length
      : 0;

    // 2. Determinar estado online
    const isOnline = numConnections > 0;

    // 3. Actualizar Firestore
    try {
      await firestore.doc(`users/${userId}`).update({
        isOnline: isOnline,
        lastOnline: isOnline
          ? null
          : admin.firestore.FieldValue.serverTimestamp(),
      });
      const status = isOnline ? "🟢 online" : "🔴 offline";
      console.log(
        `✔️ Usuario ${userId} actualizado: ${status}, Conexiones activas: ${numConnections}`,
      );
    } catch (error) {
      console.error(`❌ Error en usuario ${userId}:`, error);
    }
  });

/*borrado de sesiones
  usando CloudTask hacer que cada coneccion se expire automaticamente pasadas 6horas y que esa misma tarea se posterge en caso de activarse esa misma coneccion
  const { CloudTasksClient } = require('@google-cloud/tasks');
  EXPIRATION QUEUE= 'presence-expiration-queue-test';
  
  
  
  Mejoras implementadas:

Monitoreo por conexión individual: La función ahora observa cada conexión específica (/users/{uid}/connections/{connectionId}) en lugar de todo el nodo de conexiones, lo que permite un mejor seguimiento.
Expiración automática: Cada conexión se programa para expirar después de 6 horas mediante Cloud Tasks.
Postergación inteligente: Si se detecta actividad en una conexión existente, se cancela la tarea de expiración anterior y se crea una nueva con 6 horas adicionales.
Endpoint HTTP para expiración: Se implementa un endpoint HTTP seguro que Cloud Tasks llamará para realizar la expiración.
Verificación de seguridad: Se incluye un sistema de token para asegurar que solo Cloud Tasks pueda invocar el endpoint de expiración.
Gestión eficiente de conexiones: El sistema verifica el estado de las conexiones antes de marcar a un usuario como offline.

Para implementar esta solución:

Crea la cola de Cloud Tasks:
bashCopiargcloud tasks queues create presence-expiration-queue-test

Configura el token de seguridad:
bashCopiarfirebase functions:config:set tasks.security_token="un-token-seguro-y-aleatorio"

Despliega la función:
bashCopiarfirebase deploy --only functions:userPresenceCloud,functions:expireConnection


Esta implementación se integra perfectamente con tu código Flutter existente sin requerir cambios, ya que sigue usando el mismo modelo de datos en la Realtime Database. Ahora las conexiones expirarán automáticamente después de 6 horas de inactividad, mejorando la precisión del estado online/offline de tus usuarios.
  
  
  
  
  
  
  
  
  const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { CloudTasksClient } = require('@google-cloud/tasks');

// Para evitar errores de despliegue, no llamar a admin.initializeApp() en tu código
const firestore = admin.firestore();
const database = admin.database();

// Configuración de Cloud Tasks
const tasksClient = new CloudTasksClient();
const project = process.env.GCLOUD_PROJECT;
const location = 'us-central1'; // Ajusta según tu región
const queue = 'presence-expiration-queue-test';
const parent = tasksClient.queuePath(project, location, queue);

// Duración en segundos antes de que una conexión expire (6 horas)
const CONNECTION_EXPIRATION_SECONDS = 6 * 60 * 60;

// Cloud Function principal que maneja las conexiones
exports.userPresenceCloud = functions.database
  .ref("/users/{uid}/connections/{connectionId}")
  .onWrite(async (change, context) => {
    const userId = context.params.uid;
    const connectionId = context.params.connectionId;
    const connectionValue = change.after.val();
    
    // Si la conexión se creó o se actualizó
    if (connectionValue !== null) {
      console.log(`⚡ Nueva actividad detectada: Usuario ${userId}, Conexión ${connectionId}`);
      
      // Programar tarea para expirar esta conexión específica
      await scheduleConnectionExpiration(userId, connectionId);
      
      // Actualizar estado del usuario en Firestore
      await updateUserStatus(userId, true);
    } 
    // Si la conexión fue eliminada manualmente o por desconexión
    else if (change.before.exists()) {
      console.log(`🔌 Conexión eliminada: Usuario ${userId}, Conexión ${connectionId}`);
      
      // Cancelar cualquier tarea pendiente para esta conexión
      await cancelConnectionExpirationTask(userId, connectionId);
      
      // Verificar si quedan otras conexiones activas antes de marcar offline
      await checkAndUpdateUserStatus(userId);
    }
  });

// Cloud Function HTTP que maneja la expiración de conexiones
exports.expireConnection = functions.https.onRequest(async (req, res) => {
  // Verificar que la solicitud contenga un token de seguridad (implementa tu propia verificación)
  const securityToken = req.query.token;
  if (!securityToken || securityToken !== functions.config().tasks?.security_token) {
    console.error('🔒 Token de seguridad inválido');
    res.status(403).send('Unauthorized');
    return;
  }
  
  const userId = req.query.userId;
  const connectionId = req.query.connectionId;
  
  if (!userId || !connectionId) {
    console.error('❌ Parámetros incompletos');
    res.status(400).send('Missing parameters');
    return;
  }
  
  console.log(`⏰ Ejecutando expiración programada: Usuario ${userId}, Conexión ${connectionId}`);
  
  // Verificar si la conexión aún existe
  const connectionRef = database.ref(`/users/${userId}/connections/${connectionId}`);
  const snapshot = await connectionRef.once('value');
  
  if (snapshot.exists()) {
    // Eliminar la conexión
    await connectionRef.remove();
    console.log(`🗑️ Conexión expirada automáticamente: ${connectionId}`);
    
    // Verificar si quedan otras conexiones activas
    await checkAndUpdateUserStatus(userId);
  } else {
    console.log(`ℹ️ Conexión ${connectionId} ya no existe, no se requiere acción`);
  }
  
  res.status(200).send('OK');
});

// Función auxiliar para programar la expiración de una conexión
async function scheduleConnectionExpiration(userId, connectionId) {
  try {
    // Cancelar cualquier tarea existente para esta conexión
    await cancelConnectionExpirationTask(userId, connectionId);
    
    const url = `https://${location}-${project}.cloudfunctions.net/expireConnection`;
    const uniqueTaskName = `user-${userId}-connection-${connectionId}`;
    
    // Generar un token de seguridad (implementa tu propio método seguro)
    const securityToken = functions.config().tasks?.security_token || 'default-token';
    
    // Configurar la nueva tarea
    const task = {
      httpRequest: {
        httpMethod: 'GET',
        url: `${url}?userId=${userId}&connectionId=${connectionId}&token=${securityToken}`
      },
      scheduleTime: {
        seconds: Date.now() / 1000 + CONNECTION_EXPIRATION_SECONDS
      },
      name: `projects/${project}/locations/${location}/queues/${queue}/tasks/${uniqueTaskName}`
    };
    
    // Crear o actualizar la tarea
    await tasksClient.createTask({ parent, task });
    
    console.log(`⏱️ Tarea programada: ${uniqueTaskName} expirará en ${CONNECTION_EXPIRATION_SECONDS / 3600} horas`);
  } catch (error) {
    console.error(`❌ Error al programar expiración:`, error);
  }
}

// Función auxiliar para cancelar una tarea existente
async function cancelConnectionExpirationTask(userId, connectionId) {
  try {
    const uniqueTaskName = `user-${userId}-connection-${connectionId}`;
    const taskPath = `projects/${project}/locations/${location}/queues/${queue}/tasks/${uniqueTaskName}`;
    
    await tasksClient.deleteTask({ name: taskPath }).catch(err => {
      // Ignorar error si la tarea no existe
      if (err.code !== 5) { // 5 = NOT_FOUND
        throw err;
      }
    });
    
    console.log(`🗑️ Tarea anterior cancelada: ${uniqueTaskName}`);
  } catch (error) {
    // Solo logear errores significativos (ignorar "not found")
    if (error.code !== 5) {
      console.error(`❌ Error al cancelar tarea:`, error);
    }
  }
}

// Función para verificar conexiones activas y actualizar estado
async function checkAndUpdateUserStatus(userId) {
  try {
    const connectionsRef = database.ref(`/users/${userId}/connections`);
    const snapshot = await connectionsRef.once('value');
    const connections = snapshot.val();
    
    const hasActiveConnections = connections !== null && Object.keys(connections).length > 0;
    
    await updateUserStatus(userId, hasActiveConnections);
  } catch (error) {
    console.error(`❌ Error al verificar conexiones:`, error);
  }
}

// Función para actualizar el estado del usuario en Firestore
async function updateUserStatus(userId, isOnline) {
  try {
    await firestore.doc(`users/${userId}`).update({
      isOnline: isOnline,
      lastOnline: isOnline ? null : admin.firestore.FieldValue.serverTimestamp(),
    });
    
    const status = isOnline ? "🟢 online" : "🔴 offline";
    console.log(`✔️ Usuario ${userId} actualizado: ${status}`);
  } catch (error) {
    console.error(`❌ Error en usuario ${userId}:`, error);
  }
}
*/

/*borrado de tareas y sesiones
Componentes principales:

Cloud Function Original (userPresenceCloud)

Se mantiene exactamente igual que en tu implementación original
Sigue actualizando el estado online/offline en Firestore basado en las conexiones RTDB


Monitoreo de Conexiones (monitorConnection)

Se activa cuando se crea una nueva conexión en RTDB
Programa una tarea de expiración específica para esa conexión


Monitoreo de Estado de Usuario (monitorUserStatus)

Se activa cuando el estado online/offline del usuario cambia en Firestore
Si el usuario cambia a offline, limpia todas las conexiones RTDB y cancela las tareas pendientes


Expiración de Conexión (expireConnection)

Es llamada por Cloud Tasks cuando una conexión debe expirar
Elimina solo la conexión específica que ha expirado



Flujo de trabajo:

Cuando un usuario se conecta:

Tu código Flutter crea una entrada en RTDB (/users/{uid}/connections/{connectionId})
monitorConnection detecta esta nueva conexión y programa una tarea de expiración
userPresenceCloud actualiza el estado del usuario a online en Firestore


Cuando un usuario se desconecta normalmente:

Tu código Flutter elimina la entrada en RTDB
userPresenceCloud actualiza el estado del usuario a offline en Firestore
monitorUserStatus detecta el cambio a offline y cancela todas las tareas pendientes


Cuando una conexión expira (después de 6 horas):

Cloud Tasks llama a expireConnection
La función elimina solo la conexión específica que expiró
userPresenceCloud actualiza el estado del usuario a offline si era la última conexión



Ventajas de esta implementación:

Manejo individualizado: Cada conexión tiene su propia tarea de expiración, lo que permite manejar múltiples sesiones simultáneas.
Limpieza automática: Si un usuario se desconecta normalmente, todas sus tareas pendientes se cancelan para evitar operaciones innecesarias.
Compatibilidad con tu código existente: No requiere cambios en tu código Flutter ni en tu Cloud Function original.
Eficiencia: Solo se programan tareas para conexiones específicas y se cancelan cuando ya no son necesarias.

Implementación:

Crea la cola de Cloud Tasks:
bashCopiargcloud tasks queues create presence-expiration-queue-test

Configura el token de seguridad:
bashCopiarfirebase functions:config:set tasks.security_token="un-token-seguro-y-aleatorio"

Despliega las funciones:
bashCopiarfirebase deploy --only functions





// Primera Cloud Function (original) - Mantiene el estado online/offline
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Para evitar errores de despliegue, no llamar a admin.initializeApp() en tu código
const firestore = admin.firestore();

exports.userPresenceCloud = functions.database
  .ref("/users/{uid}/connections")
  .onWrite(async (change, context) => {
    const connections = change.after.val();
    const userId = context.params.uid;
    // 1. Calcular número de conexiones
    const isConnectionsObject = connections !== null && typeof connections === "object";
    const numConnections = isConnectionsObject ? Object.keys(connections).length : 0;
    // 2. Determinar estado online
    const isOnline = numConnections > 0;
    // 3. Actualizar Firestore
    try {
      await firestore.doc(`users/${userId}`).update({
        isOnline: isOnline,
        lastOnline: isOnline ? null : admin.firestore.FieldValue.serverTimestamp(),
      });
      const status = isOnline ? "🟢 online" : "🔴 offline";
      console.log(`✔️ Usuario ${userId} actualizado: ${status}, Conexiones activas: ${numConnections}`);
    } catch (error) {
      console.error(`❌ Error en usuario ${userId}:`, error);
    }
  });

// Segunda Cloud Function - Gestiona la expiración de conexiones específicas
const { CloudTasksClient } = require('@google-cloud/tasks');
const database = admin.database();

// Configuración de Cloud Tasks
const tasksClient = new CloudTasksClient();
const project = process.env.GCLOUD_PROJECT;
const location = 'us-central1'; // Ajusta según tu región
const queue = 'presence-expiration-queue-test';
const parent = tasksClient.queuePath(project, location, queue);

// Duración en segundos antes de que una conexión expire (6 horas)
const CONNECTION_EXPIRATION_SECONDS = 6 * 60 * 60;

// Función que se activa cuando se crea una nueva conexión en RTDB
exports.monitorConnection = functions.database
  .ref("/users/{uid}/connections/{connectionId}")
  .onCreate(async (snapshot, context) => {
    const userId = context.params.uid;
    const connectionId = context.params.connectionId;
    
    console.log(`🔔 Nueva conexión detectada - Usuario: ${userId}, Conexión: ${connectionId}`);
    
    // Programar tarea para esta conexión específica
    await scheduleConnectionExpiration(userId, connectionId);
    
    return null;
  });

// Función que observa cambios en el estado online/offline en Firestore
exports.monitorUserStatus = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;
    
    // Si el usuario cambió de online a offline
    if (before.isOnline && !after.isOnline) {
      console.log(`🔴 Usuario ${userId} cambió a offline, limpiando conexiones`);
      
      try {
        // Obtener todas las conexiones del usuario
        const connectionsRef = database.ref(`/users/${userId}/connections`);
        const snapshot = await connectionsRef.once('value');
        const connections = snapshot.val();
        
        if (connections) {
          // Para cada conexión, cancelar su tarea y eliminarla
          for (const connectionId of Object.keys(connections)) {
            await cancelConnectionTask(userId, connectionId);
            await connectionsRef.child(connectionId).remove();
            console.log(`🗑️ Conexión ${connectionId} eliminada para usuario ${userId}`);
          }
        }
      } catch (error) {
        console.error(`❌ Error al limpiar conexiones:`, error);
      }
    }
    
    return null;
  });

// Cloud Function HTTP que expira una conexión específica
exports.expireConnection = functions.https.onRequest(async (req, res) => {
  // Verificar seguridad
  const securityToken = req.query.token;
  if (!securityToken || securityToken !== functions.config().tasks?.security_token) {
    console.error('🔒 Token de seguridad inválido');
    res.status(403).send('Unauthorized');
    return;
  }
  
  const userId = req.query.userId;
  const connectionId = req.query.connectionId;
  
  if (!userId || !connectionId) {
    console.error('❌ Parámetros incompletos');
    res.status(400).send('Missing parameters');
    return;
  }
  
  try {
    console.log(`⏰ Expirando conexión - Usuario: ${userId}, Conexión: ${connectionId}`);
    
    // Verificar si la conexión todavía existe
    const connectionRef = database.ref(`/users/${userId}/connections/${connectionId}`);
    const snapshot = await connectionRef.once('value');
    
    if (snapshot.exists()) {
      // Eliminar la conexión
      await connectionRef.remove();
      console.log(`✅ Conexión ${connectionId} expirada automáticamente`);
      
      // No necesitamos actualizar el estado del usuario porque la función userPresenceCloud
      // ya se encargará de eso cuando detecte el cambio en las conexiones
    } else {
      console.log(`ℹ️ Conexión ${connectionId} ya no existe`);
    }
    
    res.status(200).send('OK');
  } catch (error) {
    console.error(`❌ Error al expirar conexión:`, error);
    res.status(500).send('Internal Server Error');
  }
});

// Función auxiliar para programar tarea de expiración para una conexión específica
async function scheduleConnectionExpiration(userId, connectionId) {
  try {
    const url = `https://${location}-${project}.cloudfunctions.net/expireConnection`;
    const uniqueTaskName = `connection-${userId}-${connectionId}`;
    
    // Generar un token de seguridad
    const securityToken = functions.config().tasks?.security_token || 'default-token';
    
    // Configurar la tarea
    const task = {
      httpRequest: {
        httpMethod: 'GET',
        url: `${url}?userId=${userId}&connectionId=${connectionId}&token=${securityToken}`
      },
      scheduleTime: {
        seconds: Date.now() / 1000 + CONNECTION_EXPIRATION_SECONDS
      },
      name: `projects/${project}/locations/${location}/queues/${queue}/tasks/${uniqueTaskName}`
    };
    
    // Crear la tarea
    await tasksClient.createTask({ parent, task });
    
    console.log(`⏱️ Tarea programada: ${uniqueTaskName} expirará en ${CONNECTION_EXPIRATION_SECONDS / 3600} horas`);
  } catch (error) {
    console.error(`❌ Error al programar tarea:`, error);
  }
}

// Función auxiliar para cancelar una tarea de expiración
async function cancelConnectionTask(userId, connectionId) {
  try {
    const uniqueTaskName = `connection-${userId}-${connectionId}`;
    const taskPath = `projects/${project}/locations/${location}/queues/${queue}/tasks/${uniqueTaskName}`;
    
    await tasksClient.deleteTask({ name: taskPath }).catch(err => {
      // Ignorar error si la tarea no existe
      if (err.code !== 5) { // 5 = NOT_FOUND
        throw err;
      }
    });
    
    console.log(`🗑️ Tarea cancelada: ${uniqueTaskName}`);
  } catch (error) {
    // Solo logear errores significativos (ignorar "not found")
    if (error.code !== 5) {
      console.error(`❌ Error al cancelar tarea:`, error);
    }
  }
}
*/
