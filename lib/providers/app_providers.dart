import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction_result.dart';
import '../services/tflite_service.dart';
import '../services/camera_service.dart';

final tfliteServiceProvider = Provider((ref) => TFLiteService());
final cameraServiceProvider = Provider((ref) => CameraService());

final predictionProvider = StateProvider<PredictionResult?>((ref) => null);
final isModelLoadedProvider = StateProvider<bool>((ref) => false);
final isProcessingProvider = StateProvider<bool>((ref) => false);
final hasErrorProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String>((ref) => '');
