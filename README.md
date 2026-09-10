# Manglares - Detector de Enfermedades

![Flutter](https://img.shields.io/badge/flutter-3.x-blue.svg?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-3.x-teal.svg?style=flat&logo=dart&logoColor=white)
![YOLO](https://img.shields.io/badge/YOLO-TFLite-green.svg?style=flat)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Aplicación Flutter para detección de enfermedades y especies de manglares usando YOLO en tiempo real.

## Requisitos

- Flutter SDK >= 3.2.0
- Android SDK
- Modelo YOLO en formato TFLite

## Instalación

1. **Clonar el proyecto**
```bash
git clone https://github.com/dacc-code/Prototype.git
cd Prototype
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Agregar el modelo YOLO**
   - Descarga tu modelo YOLO exportado a TFLite
   - Colócalo en `assets/best_float32.tflite`

4. **Ejecutar**
```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── screens/
│   ├── home_screen.dart      # Pantalla de inicio
│   ├── camera_screen.dart    # Cámara con detección en tiempo real
│   └── result_screen.dart    # Resultados del análisis
├── services/
│   ├── camera_service.dart   # Servicio de cámara
│   ├── model_service.dart    # Servicio del modelo TFLite
│   └── api_service.dart      # Servicio de API para enviar detecciones
├── models/
│   └── detection.dart        # Modelos de datos y enfermedades
└── widgets/
    └── bounding_box.dart     # Widget para dibujar bounding boxes
```

## Especies y Enfermedades Detectables

### Especies de Mangle (Saludables)
- **Dieback-Gall**: Enfermedad que causa muerte regresiva y agallas
- **Lumnitzera Littorea**: Especie de mangle - saludable
- **Lumnitzera Littorea Flower**: Mangle en floración
- **Rhizophora Apiculata**: Especie de mangle rojo
- **Rhizophora Apiculata Propagule**: Mangle rojo en propagación
- **Scyphiphora Hydrophyllacea**: Especie de mangle
- **Scyphiphora Hydrophyllacea Flower**: Mangle en floración
- **Sonneratia Alba**: Especie de mangle blanco
- **Sonneratia Alba Flower**: Mangle blanco en floración

### Enfermedades
- **Black Spots** (Manchas Negras): Infección fúngica
- **Brown Spots** (Manchas Marrones): Enfermedad fúngica
- **White Spots** (Manchas Blancas): Infección bacterial o fúngica

## Dependencias

- `camera`: Acceso a cámara
- `tflite_flutter_custom`: Inferencia del modelo TFLite
- `permission_handler`: Permisos de runtime
- `http`: Comunicación con API
- `image`: Procesamiento de imágenes
- `path_provider`: Acceso al sistema de archivos

## Características

- Detección en tiempo real con YOLO (umbral de confianza 0.04 + NMS, ver `lib/services/model_service.dart`)
- Bounding boxes con CustomPainter
- UI en español
- Información de enfermedades y recomendaciones
- Envío de detecciones a API externa

## Optimizaciones

- Procesamiento en isolates (multithreading)
- Throttling de frames para controlar FPS
- Preprocesamiento optimizado de imágenes

## Configuración del Modelo

Edita `lib/models/detection.dart` para modificar los labels del modelo:

```dart
final labels = ['Dieback-Gall', 'Lumnitzera-Littorea', ...];
```

## Licencia

MIT — ver [LICENSE](LICENSE).

## Notas para reclutadores / TODO

- TODO: el test actual (`test/widget_test.dart`) es la plantilla contador de Flutter, no prueba la app; el CI solo compila el APK.
- TODO: la URL del backend (`api_service.dart`) está fija a producción; mover a configuración (`--dart-define` o env).
- TODO: el modelo `assets/best_float32.tflite` (~10 MB) está commiteado en el repo; evaluar Git LFS.
- TODO: agregar screenshots/demo del APK.