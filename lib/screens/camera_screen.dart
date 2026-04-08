import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/model_service.dart';
import '../models/detection.dart';
import '../widgets/bounding_box.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ModelService _modelService = ModelService();
  
  bool _isLoading = true;
  bool _isDetecting = false;
  String? _error;
  List<Detection> _detections = [];
  int _fps = 0;
  DateTime _lastFrameTime = DateTime.now();
  int _frameCount = 0;
  String? _currentImageBase64;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cameraService.initialize();
      await _modelService.loadModel();
      setState(() => _isLoading = false);
      _startDetection();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startDetection() {
    _cameraService.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    _frameCount++;
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inSeconds >= 1) {
      setState(() => _fps = _frameCount);
      _frameCount = 0;
      _lastFrameTime = now;
    }

    try {
      final bytes = _convertCameraImage(image);
      if (bytes != null) {
        final detections = await _modelService.detect(bytes);
        if (mounted) {
          setState(() {
            _detections = detections;
            if (detections.isNotEmpty) {
              _currentImageBase64 = base64Encode(bytes);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Uint8List? _convertCameraImage(CameraImage image) {
    try {
      final yPlane = image.planes[0].bytes;
      final width = image.width;
      final height = image.height;

      final rgba = Uint8List(width * height * 4);
      for (int i = 0; i < width * height; i++) {
        final y = yPlane[i];
        rgba[i * 4] = y;
        rgba[i * 4 + 1] = y;
        rgba[i * 4 + 2] = y;
        rgba[i * 4 + 3] = 255;
      }

      return rgba;
    } catch (e) {
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _modelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Iniciando cámara...',
                style: TextStyle(color: Colors.white),
              ),
              if (!_modelService.isLoaded)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Cargando modelo IA...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initialize();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _cameraService.controller != null
                ? CameraPreview(_cameraService.controller!)
                : const Center(child: Text('No camera', style: TextStyle(color: Colors.white))),
          ),
          if (_detections.isNotEmpty)
            Positioned.fill(
              child: BoundingBoxWidget(
                detections: _detections,
                imageWidth: 1.0,
                imageHeight: 1.0,
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_fps FPS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _detections.isEmpty 
                          ? Colors.grey.withOpacity(0.8)
                          : Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_detections.length} detección${_detections.length != 1 ? 'es' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_detections.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  top: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _showResults(),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Ver Detalles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          detections: _detections,
          imageBase64: _currentImageBase64,
        ),
      ),
    );
  }
}
