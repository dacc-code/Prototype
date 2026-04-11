# AGENTS.md - Mangrove Disease Detector

## Quick Start
```bash
flutter pub get
flutter run
```

## Requirements
- Flutter SDK >= 3.2.0
- Android SDK
- TFLite model at `assets/best_float32.tflite` (YOLO modelo entrenado con 12 clases)

## Project Structure
- `lib/main.dart` - Entry point
- `lib/screens/` - home_screen, camera_screen, result_screen
- `lib/services/` - camera_service, model_service (TFLite), api_service
- `lib/models/detection.dart` - Detection data model and labels
- `lib/widgets/bounding_box.dart` - CustomPainter for drawing detection boxes

## Key Dependencies
- `camera` - Camera access
- `tflite_flutter_custom` - TFLite model inference (NO usar `tflite_flutter`)
- `image_picker` - Gallery/camera image selection
- `permission_handler` - Runtime permissions

## Common Tasks
- Run on device/emulator: `flutter run`
- Run on specific device: `flutter run -d <device_id>` (use `flutter devices` to list)
- Build APK: `flutter build apk --debug`

## Model Details (IMPORTANT)
- **Modelo**: YOLO con 12 clases (no estándar 80)
- **Input size**: 416x416
- **Output shape**: [1, 25200, 85] - 25200 detecciones, 85 valores (4 coords + 1 objectness + 80 classes, pero solo 12 usadas)
- **Labels**: Dieback-Gall, Lumnitzera-Littorea, Lumnitzera-Littorea-Flower, Rhizophora-Apiculata, Rhizophora-Apiculata-Propagule, Scyphiphora-Hydrophyllacea, Scyphiphora-Hydrophyllacea-Flower, Sonneratia-Alba, Sonneratia-Alba-Flower, Black Spots, Brown Spots, White Spots
- **Post-processing**: Require sigmoid activation on scores and NMS (Non-Maximum Suppression)

## Critical Implementation Notes
- **NO usar isolate para inference**: `Interpreter.fromAsset()` retorna `Future<Interpreter>`, no se puede usar en isolate. Hacer inference directamente en el hilo principal después de cargar el modelo con `await`.
- **Usar TensorBuffer para input/output**: NO usar listas de Dart directamente. Usar `TensorBuffer.createFixedSize()` con el shape correcto del modelo. El error "bad state: failed precondition" se debe a formato de tensor incorrecto.
- Cargar modelo en `loadModel()` con `await Interpreter.fromAsset('assets/best_float32.tflite')`
- Input: `TensorBuffer.createFixedSize([1, 3, 416, 416], TfLiteType.float32)`
- Output: `TensorBuffer.createFixedSize([1, 25200, 85], TfLiteType.float32)`
- Inference: `_interpreter!.run(inputBuffer.buffer, outputBuffer.buffer)`
- Usar letterbox resize (mantener aspect ratio, padding gris 128,128,128)
- Aplicar sigmoid a objectness score y class scores
- Threshold: 0.3 confidence, 0.5 NMS IOU

## Important Notes
- Model labels are defined in `lib/models/detection.dart` - update there to change detected disease names
- Assets folder must contain the TFLite model file before running
- The app is configured for Spanish UI

## CI/CD
- GitHub Actions workflow builds APK automatically on push to main
- Workflow file: `.github/workflows/flutter.yml`