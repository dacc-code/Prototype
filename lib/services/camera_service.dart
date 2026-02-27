import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'log_service.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;

  Future<void> initialize(Function(CameraImage) onFrameAvailable) async {
    logger.addLog('Iniciando CameraService...');
    final status = await Permission.camera.request();
    if (status.isDenied) {
      logger.addLog('Error: Permiso de cámara denegado');
      return;
    }
    logger.addLog('Permiso de cámara concedido');

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      logger.addLog('Error: No se encontraron cámaras');
      return;
    }
    logger.addLog(
        'Cámaras encontradas: ${cameras.length}. Seleccionando la primera.');

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      logger.addLog('Controlador de cámara inicializado con formato yuv420');
      await _controller!.startImageStream(onFrameAvailable);
      logger.addLog('Image stream iniciado exitosamente');
      _isInitialized = true;
    } catch (e) {
      logger.addLog("Camera Error: $e");
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}
