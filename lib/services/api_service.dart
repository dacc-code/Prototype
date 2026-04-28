import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/detection.dart';

class ApiService {
  static const String _baseUrl = 'https://iot-backend-1-3rru.onrender.com/api';

  static Future<bool> sendDetection(Detection detection, String imageBase64) async {
    try {
      final payload = {
        'label': detection.label,
        'label_name': _getLabelName(detection.label),
        'confidence': detection.confidence,
        'dispositivo_id': 'app-movil',
        'image_base64': imageBase64,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/detections'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending detection: $e');
      return false;
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