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
- **Modelo**: YOLO exportado a TFLite float32 con NMS incluido (`assets/best_float32.tflite`), 12 clases
- **Input size**: auto-detectado del tensor (default 640x640 si falla la lectura; NO asumir 416)
- **Output shape**: auto-detectado, formato decodificado `[1, N, 6] = [ymin, xmin, ymax, xmax, confidence, classId]` (ej. `[1, 300, 6]`). NO es YOLO crudo `[1, 25200, 85]`.
- **Labels**: Dieback-Gall, Lumnitzera-Littorea, Lumnitzera-Littorea-Flower, Rhizophora-Apiculata, Rhizophora-Apiculata-Propagule, Scyphiphora-Hydrophyllacea, Scyphiphora-Hydrophyllacea-Flower, Sonneratia-Alba, Sonneratia-Alba-Flower, Black Spots, Brown Spots, White Spots
- **Post-processing**: scores ya vienen como probabilidad (NO aplicar sigmoid), solo umbral + NMS manual

## Critical Implementation Notes
- **NO usar isolate para inference**: `Interpreter.fromAsset()` retorna `Future<Interpreter>`, no se puede usar en isolate. Hacer inference directamente en el hilo principal después de cargar el modelo con `await`.
- **Usar Float32List + reshape**: input `Float32List(H*H*3)` normalizado `/255` con `.reshape([1, H, H, 3])`, output `.reshape([1, N, 6])`. El error "bad state: failed precondition" se debe a forma de tensor incorrecta (por eso el reshape).
- Cargar modelo en `loadModel()` con `await Interpreter.fromAsset('assets/best_float32.tflite')` + `allocateTensors()`, luego leer `getInputTensors()[0].shape` y `getOutputTensors()[0].shape` (no hardcodear).
- Usar letterbox resize (mantener aspect ratio, padding gris 128,128,128) y revertir el padding al mapear boxes a la imagen original.
- NO hay `_sigmoid` en el path activo (era de un export YOLO crudo anterior; se elimino por no usarse tras verificar que los scores ya vienen como probabilidad).
- Threshold: 0.04 confidence, 0.5 NMS IOU

## Important Notes
- Model labels are defined in `lib/models/detection.dart` - update there to change detected disease names
- Assets folder must contain the TFLite model file before running
- The app is configured for Spanish UI

## CI/CD
- GitHub Actions: `build_apk.yml` (APK release en push a main) + `ci.yml` (pub get + analyze en push/PR).
- Solo errores bloquean `ci.yml` (`--no-fatal-warnings --no-fatal-infos`).