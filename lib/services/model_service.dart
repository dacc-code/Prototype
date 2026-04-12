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
      
      final options = InterpreterOptions();
      options.threads = 4;
      
      _interpreter = await Interpreter.fromAsset(
        'assets/best_float32.tflite',
        options: options,
      );
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

  List<Detection> runInference(Float32List imageBytes, int width, int height) {
    if (_interpreter == null || !_isLoaded) {
      debugPrint('Modelo no cargado');
      return [];
    }

    try {
      debugPrint('=== INICIANDO INFERENCIA ===');
      debugPrint('Input size: $_inputSize, numDetections: $_numDetections, numValues: $_numValues');
      
      final input = Float32List(_inputSize * _inputSize * 3);
      
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final origX = (x * width / _inputSize).clamp(0, width - 1).toInt();
          final origY = (y * height / _inputSize).clamp(0, height - 1).toInt();
          
          final pixel = _getPixelClamped(imageBytes, width, height, origX, origY);
          final idx = (y * _inputSize + x) * 3;
          input[idx] = pixel[0];
          input[idx + 1] = pixel[1];
          input[idx + 2] = pixel[2];
        }
      }
      
      final output = Float32List(_numDetections * _numValues);
      
      // Aseguramos la forma exacta que requiere el modelo usando reshape
      final inputReshaped = input.reshape([1, _inputSize, _inputSize, 3]);
      final outputReshaped = output.reshape([1, _numDetections, _numValues]);
      
      debugPrint('Antes de run(): input shape: [1,$_inputSize,$_inputSize,3], output shape: [1,$_numDetections,$_numValues]');
      
      // Ejecutamos inferencia evitando error de Failed Precondition
      _interpreter!.run(inputReshaped, outputReshaped);
      
      debugPrint('Despues de run()');
      
      final detections = <Detection>[];
      
      for (int i = 0; i < _numDetections; i++) {
        // Mapeamos los resultados desde el tensor de salida (ya no es un array 1D)
        final prediction = outputReshaped[0][i];
        
        final confidence = prediction[4];
        
        if (confidence < 0.4) continue;
        
        final classId = prediction[5].toInt();
        final cx = prediction[0];
        final cy = prediction[1];
        final w = prediction[2];
        final h = prediction[3];
        
        detections.add(Detection(
          label: classId.toString(),
          confidence: confidence,
          x: cx - w / 2,
          y: cy - h / 2,
          width: w,
          height: h,
        ));
        
        if (i == 0) { // Opcional: imprimir el score de la primera deteccion
           debugPrint('--- PRIMERA DETECCION (Index $i) ---');
           debugPrint('Score (Confidence): $confidence, ClassID: $classId');
           debugPrint('Box: [$cx, $cy, $w, $h]');
        } else if (i < 3) {
          debugPrint('Deteccion[$i]: conf=$confidence, class=$classId, box=[$cx,$cy,$w,$h]');
        }
      }
      
      debugPrint('Detecciones antes de NMS: ${detections.length}');
      
      final filtered = _nonMaxSuppression(detections, 0.5);
      debugPrint('Detecciones despues de NMS: ${filtered.length}');
      
      return filtered;
    } catch (e, st) {
      debugPrint('ERROR en inferencia: $e');
      debugPrint('Stack: $st');
      return [];
    }
  }

  List<double> _getPixelClamped(Float32List data, int width, int height, int x, int y) {
    x = x.clamp(0, width - 1);
    y = y.clamp(0, height - 1);
    final idx = (y * width + x) * 3;
    return [
      data[idx].clamp(0.0, 1.0),
      data[idx + 1].clamp(0.0, 1.0),
      data[idx + 2].clamp(0.0, 1.0),
    ];
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
      
      log += 'Creando input [1,$actualInputSize,$actualInputSize,$channels] con Float32List\n';
      debugPrint('Creando input con Float32List de tamano: ${actualInputSize * actualInputSize * channels}');

      final input = Float32List(actualInputSize * actualInputSize * channels);

      for (int y = 0; y < actualInputSize; y++) {
        for (int x = 0; x < actualInputSize; x++) {
          final pixel = resized.getPixel(x, y);
          final idx = (y * actualInputSize + x) * channels;
          input[idx] = pixel.r / 255.0;
          input[idx + 1] = pixel.g / 255.0;
          input[idx + 2] = pixel.b / 255.0;
        }
      }
      
      log += 'Input[0]: [${input[0]}, ${input[1]}, ${input[2]}]\n';
      debugPrint('Input[0]: ${input[0]}, ${input[1]}, ${input[2]}');

      final output = Float32List(_numDetections * _numValues);
      
      // Aplicamos reshape al input y output para evitar el Failed Precondition
      final inputReshaped = input.reshape([1, actualInputSize, actualInputSize, channels]);
      final outputReshaped = output.reshape([1, _numDetections, _numValues]);

      log += 'Output buffer: [1, $_numDetections, $_numValues] formateado con reshape\n';

      debugPrint('Antes de interpreter.run()');
      try {
        _interpreter!.run(inputReshaped, outputReshaped);
        debugPrint('Despues de interpreter.run() - EXITO');
      } catch (e, st) {
        debugPrint('ERROR en run(): $e');
        debugPrint('Stack: $st');
        return DetectionResult(detections: [], log: '$log\nError en run(): $e');
      }
      log += 'run() completado!\n';

      log += 'Procesando $_numDetections detecciones...\n';

      final detections = <Detection>[];

      for (int i = 0; i < _numDetections; i++) {
        // Mapeamos los resultados desde el tensor reshaped [1, 300, 6]
        final prediction = outputReshaped[0][i];
        
        final confidence = prediction[4];
        if (confidence < 0.4) continue;
        
        final classId = prediction[5].toInt();
        final classIdSafe = classId.clamp(0, _labels.length - 1);

        final cx = prediction[0];
        final cy = prediction[1];
        final w = prediction[2];
        final h = prediction[3];

        detections.add(Detection(
          label: classIdSafe.toString(),
          confidence: confidence,
          x: cx - w / 2,
          y: cy - h / 2,
          width: w,
          height: h,
        ));

        if (i == 0) { // Opcional: imprimir el score de la primera deteccion
           log += '  [DETECT 0] Score=$confidence, ClassID=$classIdSafe\n';
           debugPrint('Primera Deteccion Score: $confidence');
        } else if (i < 3) {
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