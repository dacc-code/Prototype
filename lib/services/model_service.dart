import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter_custom/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection.dart';

class DetectionResult {
  final List<Detection> detections;
  final String log;

  DetectionResult({required this.detections, required this.log});
}

class ModelService {
  Interpreter? _interpreter;
  bool _isLoaded = false;
  final int _inputSize = 416;
  final double _confidenceThreshold = 0.5;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      _isLoaded = true;
      debugPrint('Model loaded successfully');
    } catch (e) {
      debugPrint('Error loading model: $e');
      _isLoaded = false;
    }
  }

  Future<List<Detection>> detect(Uint8List imageBytes) async {
    if (_interpreter == null || !_isLoaded) {
      return [];
    }

    try {
      return await compute(_runInference, {
        'imageBytes': imageBytes,
        'interpreterAddress': _interpreter!.address,
      });
    } catch (e) {
      debugPrint('Detection error: $e');
      return [];
    }
  }

  Future<DetectionResult> detectWithDebug(Uint8List imageBytes) async {
    if (_interpreter == null || !_isLoaded) {
      return DetectionResult(detections: [], log: 'Modelo no cargado');
    }

    try {
      return await compute(_runInferenceWithDebug, {
        'imageBytes': imageBytes,
        'interpreterAddress': _interpreter!.address,
      });
    } catch (e) {
      debugPrint('Detection error: $e');
      return DetectionResult(detections: [], log: 'Error: $e');
    }
  }

  static List<Detection> _runInference(Map<String, dynamic> params) {
    final Uint8List imageBytes = params['imageBytes'];
    final int interpreterAddress = params['interpreterAddress'];
    final interpreter = Interpreter.fromAddress(interpreterAddress);
    final int inputSize = 416;
    final double confidenceThreshold = 0.3;

    final image = img.decodeImage(imageBytes);
    if (image == null) return [];

    debugPrint('Image decoded: ${image.width}x${image.height}');

    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    debugPrint('Image resized to: ${resized.width}x${resized.height}');

    final input = _preprocessImage(resized, inputSize);
    debugPrint('Input shape: [1, 3, $inputSize, $inputSize]');

    final outputBuffer = List.filled(1, List.filled(25200, List.filled(85, 0.0)));
    interpreter.run(input, outputBuffer);

    debugPrint('Output shape: ${outputBuffer.length}x${outputBuffer[0].length}x${outputBuffer[0][0].length}');

    final detections = _postProcess(outputBuffer[0], confidenceThreshold, image.width, image.height);
    debugPrint('Found ${detections.length} detections');

    return detections;
  }

  static List<List<double>> _preprocessImage(img.Image image, int size) {
    final input = List.generate(
      size,
      (y) => List.generate(
        size,
        (x) {
          final pixel = image.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    );

    final transposed = [
      List<double>.from(input.map((row) => row[0])),
      List<double>.from(input.map((row) => row[1])),
      List<double>.from(input.map((row) => row[2])),
    ];

    return transposed;
  }

  static List<Detection> _postProcess(
    List<List<double>> output,
    double confidenceThreshold,
    int imageWidth,
    int imageHeight,
  ) {
    final detections = <Detection>[];
    final labels = [
      'Dieback-Gall',        // 0
      'Lumnitzera-Littorea', // 1
      'Lumnitzera-Littorea-Flower', // 2
      'Rhizophora-Apiculata', // 3
      'Rhizophora-Apiculata-Propagule', // 4
      'Scyphiphora-Hydrophyllacea', // 5
      'Scyphiphora-Hydrophyllacea-Flower', // 6
      'Sonneratia-Alba', // 7
      'Sonneratia-Alba-Flower', // 8
      'Black Spots', // 9
      'Brown Spots', // 10
      'White Spots' // 11
    ];

    for (var prediction in output) {
      final objectness = prediction[4];
      if (objectness < confidenceThreshold) continue;

      final classScores = prediction.sublist(5);
      final maxScore = classScores.reduce((a, b) => a > b ? a : b);
      final classIndex = classScores.indexOf(maxScore);

      if (maxScore < confidenceThreshold) continue;

      final confidence = objectness * maxScore;
      final cx = prediction[0];
      final cy = prediction[1];
      final w = prediction[2];
      final h = prediction[3];

      detections.add(Detection(
        label: labels[classIndex],
        confidence: confidence,
        x: (cx - w / 2) / imageWidth,
        y: (cy - h / 2) / imageHeight,
        width: w / imageWidth,
        height: h / imageHeight,
      ));
    }

    return _nonMaxSuppression(detections, 0.5);
  }

  static List<Detection> _nonMaxSuppression(
    List<Detection> detections,
    double iouThreshold,
  ) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    final keep = <Detection>[];

    while (detections.isNotEmpty) {
      keep.add(detections.removeAt(0));
      detections.removeWhere((d) => _calculateIoU(keep.last, d) > iouThreshold);
    }

    return keep;
  }

  static double _calculateIoU(Detection a, Detection b) {
    final x1 = (a.x > b.x) ? a.x : b.x;
    final y1 = (a.y > b.y) ? a.y : b.y;
    final x2 = (a.x + a.width < b.x + b.width) ? a.x + a.width : b.x + b.width;
    final y2 = (a.y + a.height < b.y + b.height) ? a.y + a.height : b.y + b.height;

    final intersection = (x2 - x1) * (y2 - y1);
    final union = a.width * a.height + b.width * b.height - intersection;

    return (intersection / union).clamp(0.0, 1.0);
  }

  static DetectionResult _runInferenceWithDebug(Map<String, dynamic> params) {
    final Uint8List imageBytes = params['imageBytes'];
    final int interpreterAddress = params['interpreterAddress'];
    final interpreter = Interpreter.fromAddress(interpreterAddress);
    final int inputSize = 416;
    final double confidenceThreshold = 0.3;

    String log = '';

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      return DetectionResult(detections: [], log: 'No se pudo decodificar imagen');
    }

    log += 'Imagen: ${image.width}x${image.height}\n';

    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    log += 'Resize: ${resized.width}x${resized.height}\n';

    final input = _preprocessImage(resized, inputSize);
    log += 'Input: [3, $inputSize, $inputSize]\n';

    final outputBuffer = List.filled(1, List.filled(25200, List.filled(85, 0.0)));
    interpreter.run(input, outputBuffer);
    log += 'Output: ${outputBuffer[0].length} predictions\n';

    final detections = _postProcess(outputBuffer[0], confidenceThreshold, image.width, image.height);
    log += 'Detecciones: ${detections.length}\n';

    if (detections.isNotEmpty) {
      for (var d in detections.take(3)) {
        log += '- ${d.label}: ${(d.confidence * 100).toStringAsFixed(1)}%\n';
      }
    }

    return DetectionResult(detections: detections, log: log);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
