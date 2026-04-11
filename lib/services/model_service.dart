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
      debugPrint('=== INICIANDO CARGA DE MODELO ===');
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      debugPrint('Modelo cargado desde asset');
      
      final inputTensors = _interpreter!.getInputTensors();
      debugPrint('Input tensors obtenidos: ${inputTensors.length}');
      
      final outputTensors = _interpreter!.getOutputTensors();
      debugPrint('Output tensors obtenidos: ${outputTensors.length}');
      
      for (var t in inputTensors) {
        debugPrint('INPUT: name=${t.name}, shape=${t.shape}, type=${t.type}');
      }
      for (var t in outputTensors) {
        debugPrint('OUTPUT: name=${t.name}, shape=${t.shape}, type=${t.type}');
      }
      
      if (inputTensors.isNotEmpty) {
        _inputSize = inputTensors[0].shape[1];
        debugPrint('Input size configurado: $_inputSize');
      }
      
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
      debugPrint('=== MODELO CARGADO EXITOSAMENTE ===');
    } catch (e, st) {
      debugPrint('Error cargando modelo: $e');
      debugPrint('Stack: $st');
      _isLoaded = false;
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

  Future<DetectionResult> detectWithDebug(Uint8List imageBytes) async {
    if (_interpreter == null || !_isLoaded) {
      return DetectionResult(detections: [], log: 'Modelo no cargado');
    }

    try {
      String log = '';
      log += '=== INICIANDO DETECCION ===\n';

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return DetectionResult(detections: [], log: 'No se pudo decodificar imagen');
      }

      log += 'Original: ${image.width}x${image.height}\n';

      final resized = _letterboxResize(image, _inputSize);
      log += 'Resize: ${resized.width}x${resized.height}\n';
      
      final inputTensors = _interpreter!.getInputTensors();
      final expectedShape = inputTensors[0].shape;
      log += 'Expected shape: $expectedShape\n';
      log += 'Expected type: ${inputTensors[0].type}\n';
      debugPrint('Expected shape por modelo: $expectedShape');
      
      final outputTensors = _interpreter!.getOutputTensors();
      final outputShape = outputTensors[0].shape;
      log += 'Output shape: $outputShape\n';
      debugPrint('Expected output por modelo: $outputShape');
      
      final actualInputSize = expectedShape[1];
      final channels = expectedShape[3];
      
      log += 'Creando input [1,$actualInputSize,$actualInputSize,$channels]\n';

      final input = List.generate(
        actualInputSize,
        (_) => List.generate(actualInputSize, (_) => List.filled(channels, 0.0)),
      );

      for (int y = 0; y < actualInputSize; y++) {
        for (int x = 0; x < actualInputSize; x++) {
          final pixel = resized.getPixel(x, y);
          input[y][x][0] = pixel.r / 255.0;
          input[y][x][1] = pixel.g / 255.0;
          input[y][x][2] = pixel.b / 255.0;
        }
      }
      
      log += 'Input[0,0,0-2]=[${input[0][0][0]},[${input[0][0][1]},[${input[0][0][2]}]\n';
      debugPrint('Input primeros valores: ${input[0][0]}');

      final numDetections = outputShape[1];
      final numValues = outputShape[2];
      log += 'Output [1,$numDetections,$numValues]\n';

      final outputBuffer = List.filled(1, List.filled(numDetections, List.filled(numValues, 0.0)));

      debugPrint('Antes de allocateTensors()');
      _interpreter!.allocateTensors();
      debugPrint('Despues de allocateTensors()');
      
      log += 'Ejecutando run()...\n';
      debugPrint('Antes de _interpreter.run()');
      try {
        _interpreter!.run(input, outputBuffer);
        debugPrint('run() completado!');
      } catch (e, st) {
        debugPrint('ERROR en run(): $e');
        debugPrint('Stack: $st');
        return DetectionResult(detections: [], log: '$log\nError en run(): $e');
      }
      log += 'run() completado!\n';

      log += 'Procesando $numDetections detecciones...\n';

      final detections = <Detection>[];
      final outputData = outputBuffer[0];

      for (int i = 0; i < numDetections; i++) {
        final prediction = outputData[i];

        final objScore = _sigmoid(prediction[4]);
        if (objScore < 0.3) continue;

        final classScores = prediction.sublist(5);
        final maxScore = classScores.reduce((a, b) => a > b ? a : b);
        final classIndex = classScores.indexOf(maxScore);
        final confScore = _sigmoid(maxScore);

        if (confScore < 0.3) continue;

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

      final filtered = _nonMaxSuppression(detections, 0.5);
      log += 'Después de NMS: ${filtered.length} detecciones\n';

      if (filtered.isNotEmpty) {
        for (var d in filtered.take(3)) {
          log += '- ${d.label}: ${(d.confidence * 100).toStringAsFixed(1)}%\n';
        }
      }

      return DetectionResult(detections: filtered, log: log);
    } catch (e) {
      debugPrint('Detection error: $e');
      return DetectionResult(detections: [], log: 'Error: $e');
    }
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