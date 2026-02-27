import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mango_disease_detector/services/camera_service.dart';
import 'package:mango_disease_detector/services/tflite_service.dart';
import 'package:mango_disease_detector/widgets/result_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MangoApp());
}

class MangoApp extends StatelessWidget {
  const MangoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detector de Enfermedades de Mango',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const DetectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final CameraService _cameraService = CameraService();
  final TFLiteService _tfliteService = TFLiteService();

  Map<String, dynamic>? _prediction;
  bool _isModelLoaded = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tfliteService.loadModel();
    setState(() {
      _isModelLoaded = true;
    });

    await _cameraService.initialize((CameraImage image) {
      if (!_isProcessing && _isModelLoaded) {
        _isProcessing = true;
        _runInference(image);
      }
    });
    setState(() {});
  }

  Future<void> _runInference(CameraImage image) async {
    final result = await _tfliteService.runInference(image);
    if (mounted) {
      setState(() {
        _prediction = result;
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraService.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_cameraService.controller!),
          ),

          // Result Overlay
          ResultOverlay(prediction: _prediction),

          // Header Overlay
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Detector de Enfermedades - Mango',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
