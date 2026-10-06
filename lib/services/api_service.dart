import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/detection.dart';
import 'auth_service.dart';

/// Resultado detallado del envio al dashboard (para mostrar en UI).
class SendResult {
  final bool ok;
  final String message;
  final String imageUrl;
  const SendResult({required this.ok, required this.message, this.imageUrl = ''});
}

class ApiService {
  static const String _baseUrl = 'https://iot-backend-1-3rru.onrender.com/api';

  /// Envia una deteccion al backend (POST /api/detections, requiere JWT).
  /// Toma el token de [AuthService.instance]; si no hay sesion devuelve
  /// ok=false con mensaje que invita a iniciar sesion (el servidor daria 401).
  static Future<SendResult> sendDetection(
      Detection detection, String imageBase64) async {
    final token = AuthService.instance.token;
    if (token == null || token.isEmpty) {
      return const SendResult(
          ok: false, message: 'Inicia sesión para enviar al dashboard.');
    }

    try {
      final payload = {
        'label': detection.label,
        'label_name': _getLabelName(detection.label),
        'confidence': detection.confidence,
        'dispositivo_id': 'app-movil',
        'image_base64': imageBase64,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/detections'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200 || response.statusCode == 201) {
        String imageUrl = '';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          imageUrl = (data['image_url'] ?? '').toString();
          final uploadError = (data['upload_error'] ?? '').toString();
          if (uploadError.isNotEmpty) {
            return SendResult(
                ok: true,
                message: 'Registrado, pero la imagen no se subió: $uploadError',
                imageUrl: imageUrl);
          }
        } catch (_) {}
        return SendResult(
            ok: true, message: 'Detección enviada al dashboard.', imageUrl: imageUrl);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const SendResult(
            ok: false,
            message: 'Sesión vencida. Vuelve a iniciar sesión.');
      }
      String detail = 'Error ${response.statusCode} del servidor.';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        detail = (data['detail'] ?? detail).toString();
      } catch (_) {}
      return SendResult(ok: false, message: detail);
    } catch (e) {
      return SendResult(ok: false, message: 'Sin conexión: $e');
    }
  }

  static String _getLabelName(String label) {
    final names = {
      '0': 'Dieback-Gall',
      '1': 'Lumnitzera-Littorea',
      '2': 'Lumnitzera-Littorea-Flower',
      '3': 'Rhizophora-Apiculata',
      '4': 'Rhizophora-Apiculata-Propagule',
      '5': 'Scyphiphora-Hydrophyllacea',
      '6': 'Scyphiphora-Hydrophyllacea-Flower',
      '7': 'Sonneratia-Alba',
      '8': 'Sonneratia-Alba-Flower',
      '9': 'Black Spots',
      '10': 'Brown Spots',
      '11': 'White Spots',
    };
    return names[label] ?? label;
  }
}
