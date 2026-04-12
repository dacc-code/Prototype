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
  int _inputSize = 640;
  int _numDetections = 300;
  int _numValues = 6;
  List<String> _labels = [];

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    try {
      debugPrint('=== INICIANDO CARGA DE MODELO ===');
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      debugPrint('Modelo cargado desde asset');
      
      _interpreter!.allocateTensors();
      debugPrint('allocateTensors() llamado');
      
      final inputTensors = _interpreter!.getInputTensors();
      debugPrint('Input tensors: ${inputTensors.length}');
      
      final outputTensors = _interpreter!.getOutputTensors();
      debugPrint('Output tensors: ${outputTensors.length}');
      
      for (var t in inputTensors) {
        debugPrint('INPUT: name=${t.name}, shape=${t.shape}, type=${t.type}');
      }
      for (var t in outputTensors) {
        debugPrint('OUTPUT: name=${t.name}, shape=${t.shape}, type=${t.type}');
      }
      
      if (inputTensors.isNotEmpty) {
        _inputSize = inputTensors[0].shape[1];
        debugPrint('Input size: $_inputSize');
      }
      
      if (outputTensors.isNotEmpty) {
        final outShape = outputTensors[0].shape;
        _numDetections = outShape[1];
        _numValues = outShape[2];
        debugPrint('Output shape: [1, $_numDetections, $_numValues]');
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
      debugPrint('=== MODELO CARGADO Y TENSORES ASIGNADOS ===');
    } catch (e, st) {
      debugPrint('Error cargando modelo: $e');
      debugPrint('Stack: $st');
      _isLoaded = false;
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
      final expectedType = inputTensors[0].type;
      log += 'Expected input: shape=$expectedShape, type=$expectedType\n';
      debugPrint('Input shape: $expectedShape');
      
      final outputTensors = _interpreter!.getOutputTensors();
      final outputShape = outputTensors[0].shape;
      log += 'Expected output: shape=$outputShape\n';
      debugPrint('Output shape: $outputShape');
      
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
      
      log += 'Input[0,0]: [${input[0][0][0]}, ${input[0][0][1]}, ${input[0][0][2]}]\n';
      debugPrint('Input[0,0]: ${input[0][0]}');

      final outputBuffer = List.filled(1, List.filled(_numDetections, List.filled(_numValues, 0.0)));

      log += 'Output buffer: [1, $_numDetections, $_numValues]\n';

      debugPrint('Antes de interpreter.run()');
      try {
        _interpreter!.run(input, outputBuffer);
        debugPrint('Despues de interpreter.run() - EXITO');
      } catch (e, st) {
        debugPrint('ERROR en run(): $e');
        debugPrint('Stack: $st');
        return DetectionResult(detections: [], log: '$log\nError en run(): $e');
      }
      log += 'run() completado!\n';

      log += 'Procesando $_numDetections detecciones...\n';

      final detections = <Detection>[];
      final outputData = outputBuffer[0];

      for (int i = 0; i < _numDetections; i++) {
        final pred = outputData[i];
        
        final confidence = pred[4].toDouble();
        if (confidence < 0.3) continue;
        
        final classId = pred[5].toInt();
        final classIdSafe = classId.clamp(0, _labels.length - 1);

        final cx = pred[0].toDouble();
        final cy = pred[1].toDouble();
        final w = pred[2].toDouble();
        final h = pred[3].toDouble();

        detections.add(Detection(
          label: classIdSafe.toString(),
          confidence: confidence,
          x: cx - w / 2,
          y: cy - h / 2,
          width: w,
          height: h,
        ));

        if (i < 3) {
          log += '  Deteccion[$i]: conf=${confidence.toStringAsFixed(3)}, class=$classId, box=[$cx,$cy,$w,$h]\n';
        }
      }

      log += 'Antes de NMS: ${detections.length} detecciones\n';

      final filtered = _nonMaxSuppression(detections, 0.5);
      log += 'Después de NMS: ${filtered.length} detecciones\n';

      if (filtered.isNotEmpty) {
        for (var d in filtered.take(3)) {
          final labelIdx = int.tryParse(d.label) ?? 0;
          final labelName = labelIdx < _labels.length ? _labels[labelIdx] : d.label;
          log += '- $labelName: ${(d.confidence * 100).toStringAsFixed(1)}%\n';
        }
      }

      return DetectionResult(detections: filtered, log: log);
    } catch (e, st) {
      debugPrint('Detection error: $e');
      debugPrint('Stack: $st');
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
    final y2 = ((a.y + a.height) < (b.y + b.height)) ? (a.y + b.height) : (b.y + b.height);

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