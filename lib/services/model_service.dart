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
  int _inputSize = 416;
  List<String> _labels = [];

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      
      _inputSize = 416;
      
      _labels = [
        'Dieback-Gall',
        'Lumnitzera-Littorea',
        'Lumnitzera-Littorea-Flower',
        'Rhizophora-Apiculata',
        'Rhizophora-Apiculata-Propagule',
        'Scyphiphora-Hydrophyllacea',
        'Scyphiphora-Hydrophyllacea-Flower',
        'Sonneratia-Alba',
        'Sonneratia-Alba-Flower',
        'Black Spots',
        'Brown Spots',
        'White Spots'
      ];
      
      _isLoaded = true;
      debugPrint('Model loaded successfully');
    } catch (e) {
      debugPrint('Error loading model: $e');
      _isLoaded = false;
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
        'inputSize': _inputSize,
      });
    } catch (e) {
      debugPrint('Detection error: $e');
      return DetectionResult(detections: [], log: 'Error: $e');
    }
  }

  static double _sigmoid(double x) {
    return 1.0 / (1.0 + _exp(-x));
  }

  static double _exp(double x) {
    if (x > 0) {
      double result = 1.0;
      double term = 1.0;
      for (int i = 1; i <= 10; i++) {
        term *= x / i;
        result += term;
      }
      return result;
    } else {
      double result = 1.0;
      double term = 1.0;
      for (int i = 1; i <= 10; i++) {
        term *= x / i;
        result += term;
      }
      return result;
    }
  }

  static DetectionResult _runInferenceWithDebug(Map<String, dynamic> params) {
    final Uint8List imageBytes = params['imageBytes'];
    final int interpreterAddress = params['interpreterAddress'];
    final int inputSize = params['inputSize'] ?? 416;
    final double confidenceThreshold = 0.3;
    final double iouThreshold = 0.5;

    String log = '';

    final image = img.decodeImage(imageBytes);
    if (image == null) {
      return DetectionResult(detections: [], log: 'No se pudo decodificar imagen');
    }

    log += 'Original: ${image.width}x${image.height}\n';

    final resized = _letterboxResize(image, inputSize);
    log += 'Resize: ${resized.width}x${resized.height}\n';

    final input = _preprocessImage(resized, inputSize);
    log += 'Input shape: [1, 3, $inputSize, $inputSize]\n';

    final interpreter = Interpreter.fromAddress(interpreterAddress);
    
    const numDetections = 25200;
    const numValues = 85;
    log += 'Output shape: [1, $numDetections, $numValues]\n';
    
    final outputBuffer = List.filled(1, List.filled(numDetections, List.filled(numValues, 0.0)));
    interpreter.run(input, outputBuffer);

    log += 'Procesando $numDetections detecciones...\n';

    final detections = <Detection>[];
    
    for (int i = 0; i < numDetections; i++) {
      final prediction = outputBuffer[0][i];
      
      final objScore = _sigmoid(prediction[4]);
      if (objScore < confidenceThreshold) continue;

      final classScores = prediction.sublist(5);
      final maxScore = classScores.reduce((a, b) => a > b ? a : b);
      final classIndex = classScores.indexOf(maxScore);
      final confScore = _sigmoid(maxScore);

      if (confScore < confidenceThreshold) continue;

      final finalConfidence = objScore * confScore;
      
      final cx = prediction[0];
      final cy = prediction[1];
      final w = prediction[2];
      final h = prediction[3];

      detections.add(Detection(
        label: classIndex.toString(),
        confidence: finalConfidence,
        x: cx - w / 2,
        y: cy - h / 2,
        width: w,
        height: h,
      ));
    }

    log += 'Antes de NMS: ${detections.length} detecciones\n';

    final filtered = _nonMaxSuppression(detections, iouThreshold);
    log += 'Después de NMS: ${filtered.length} detecciones\n';

    if (filtered.isNotEmpty) {
      for (var d in filtered.take(3)) {
        log += '- ${d.label}: ${(d.confidence * 100).toStringAsFixed(1)}%\n';
      }
    }

    return DetectionResult(detections: filtered, log: log);
  }

  static img.Image _letterboxResize(img.Image image, int size) {
    final aspectRatio = image.width / image.height;
    int newWidth, newHeight;
    int offsetX = 0, offsetY = 0;

    if (aspectRatio > 1) {
      newWidth = size;
      newHeight = (size / aspectRatio).round();
      offsetY = size - newHeight;
    } else {
      newHeight = size;
      newWidth = (size * aspectRatio).round();
      offsetX = size - newWidth;
    }

    final resized = img.copyResize(image, width: newWidth, height: newHeight);
    
    final padded = img.Image(width: size, height: size);
    img.fill(padded, color: img.ColorRgb8(128, 128, 128));
    
    img.compositeImage(padded, resized, dstX: offsetX ~/ 2, dstY: offsetY ~/ 2);
    
    return padded;
  }

  static List<List<double>> _preprocessImage(img.Image image, int size) {
    final input = List.generate(
      3,
      (_) => List.filled(size * size, 0.0),
    );

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = image.getPixel(x, y);
        final idx = y * size + x;
        input[0][idx] = pixel.r / 255.0;
        input[1][idx] = pixel.g / 255.0;
        input[2][idx] = pixel.b / 255.0;
      }
    }

    return [
      List<double>.from(input[0]),
      List<double>.from(input[1]),
      List<double>.from(input[2]),
    ];
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
    final x2 = ((a.x + a.width) < (b.x + b.width)) ? (a.x + a.width) : (b.x + b.width);
    final y2 = ((a.y + a.height) < (b.y + b.height)) ? (a.y + a.height) : (b.y + b.height);

    final intersection = (x2 - x1) * (y2 - y1);
    final union = a.width * a.height + b.width * b.height - intersection;

    return (intersection / union).clamp(0.0, 1.0);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
