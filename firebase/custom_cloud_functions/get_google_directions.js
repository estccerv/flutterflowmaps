const functions = require("firebase-functions");
const axios = require("axios");
const cors = require("cors")({ origin: true }); // <-- Necesitamos CORS

// Guarda tu API Key como una variable de entorno en Firebase para máxima seguridad

const GOOGLE_MAPS_API_KEY = "AIzaSyBtRF_qL6IMhjFTWrZqm5_01B2EZMZGs2A";
exports.getGoogleDirections = functions.https.onRequest((request, response) => {
  // Envolvemos toda la lógica en cors()
  cors(request, response, async () => {
    // Validamos los parámetros de la URL (query parameters)
    const { origin, destination } = request.query;
    if (!origin || !destination) {
      functions.logger.error("Petición sin origin o destination.");
      // Enviamos una respuesta de error clara
      return response
        .status(400)
        .send({ error: "Faltan los parámetros 'origin' y 'destination'." });
    }
    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&key=${GOOGLE_MAPS_API_KEY}`;
    try {
      functions.logger.info(`Llamando a Google API: ${url}`);
      const apiResponse = await axios.get(url);
      // Reenviamos la respuesta de Google a nuestra app
      return response.status(200).send(apiResponse.data);
    } catch (error) {
      functions.logger.error("Error al llamar a Google API:", error);
      return response
        .status(500)
        .send({ error: "Error interno al obtener la ruta." });
    }
  });
});
