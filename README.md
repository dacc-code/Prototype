# Manglares - Detector de Enfermedades

Aplicación Flutter para detección de enfermedades en manglares usando YOLO en tiempo real.

## 📋 Requisitos

- Flutter SDK >= 3.2.0
- Android SDK
- Modelo YOLO en formato TFLite

## 🚀 Instalación

1. **Clonar el proyecto**
```bash
git clone <repo-url>
cd mangrove_disease_detector
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Agregar el modelo YOLO**
   - Descarga tu modelo YOLO exportado a TFLite
   - Colócalo en `assets/yolov5s.tflite`

4. **Ejecutar**
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── screens/
│   ├── home_screen.dart      # Pantalla de inicio
│   ├── camera_screen.dart    # Cámara con detección en tiempo real
│   └── result_screen.dart    # Resultados del análisis
├── services/
│   ├── camera_service.dart   # Servicio de cámara
│   └── model_service.dart    # Servicio del modelo TFLite
├── models/
│   └── detection.dart       # Modelos de datos
└── widgets/
    └── bounding_box.dart     # Widget para dibujar bounding boxes
```

## 🎯 Enfermedades Detectables

- **Mancha Foliar (leaf_spot)**: Infección fúngica
- **Pudrición de Raíces (root_rot)**: Hongos en raíces
- **Amarillamiento Foliar (yellow_leaf)**: Deficiencia nutricional
- **Manchas Marrones (brown_spots)**: Infección fúngica
- **Tizón Foliar (leaf_blight)**: Enfermedad bacteriana
- **Mangle Saludable (healthy)**: Sin enfermedades

## ⚙️ Configuración del Modelo

### Exportar YOLO a TFLite

```python
import torch

model = torch.load('yolov5s.pt', map_location='cpu')['model'].float()
model.eval()

# Crear input tensor
img = torch.zeros(1, 3, 416, 416)

# Exportar a TFLite
torch_to_tflite(model, img, 'yolov5s.tflite')
```

### Ajustar clases del modelo

Edita `lib/models/detection.dart` para cambiar los labels:

```dart
final labels = ['leaf_spot', 'root_rot', 'yellow_leaf', 'brown_spots', 'leaf_blight', 'healthy'];
```

## 📱 Características

- ✅ Detección en tiempo real
- ✅ Bounding boxes con CustomPainter
- ✅ Optimizado con isolates
- ✅ UI en español
- ✅ Recomendaciones de tratamiento
- ✅ Control de FPS

## 🔧 Optimizaciones

- Procesamiento en isolates (multithreading)
- Throttling de frames para controlar FPS
- Preprocesamiento optimizado de imágenes

## 📄 Licencia

MIT License
