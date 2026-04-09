# AGENTS.md - Mangrove Disease Detector

## Quick Start
```bash
flutter pub get
flutter run
```

## Requirements
- Flutter SDK >= 3.2.0
- Android SDK
- YOLO model as TFLite file placed at `assets/yolov5s.tflite`

## Project Structure
- `lib/main.dart` - Entry point
- `lib/screens/` - home_screen, camera_screen, result_screen
- `lib/services/` - camera_service, model_service (TFLite), api_service
- `lib/models/detection.dart` - Detection data model and labels
- `lib/widgets/bounding_box.dart` - CustomPainter for drawing detection boxes

## Key Dependencies
- `camera` - Camera access
- `tflite_flutter_custom` - TFLite model inference
- `permission_handler` - Runtime permissions

## Common Tasks
- Run on device/emulator: `flutter run`
- Run on specific device: `flutter run -d <device_id>` (use `flutter devices` to list)
- Build APK: `flutter build apk --debug`

## Important Notes
- Model labels are defined in `lib/models/detection.dart` - update there to change detected disease names
- Assets folder must contain the TFLite model file before running
- Camera and ML inference run in isolates for performance
- The app is configured for Spanish UI