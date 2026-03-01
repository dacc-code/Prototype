import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/prediction_result.dart';
import 'providers/app_providers.dart';
import 'widgets/result_overlay.dart';
import 'widgets/debug_console.dart';
import 'services/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MangoApp()));
}

class MangoApp extends StatelessWidget {
  const MangoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mango Disease Detector Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFFFC107),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const DetectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DetectionScreen extends ConsumerStatefulWidget {
  const DetectionScreen({super.key});

  @override
  ConsumerState<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends ConsumerState<DetectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final tflite = ref.read(tfliteServiceProvider);
    final camera = ref.read(cameraServiceProvider);

    logger.addLog('Iniciando aplicación AI...');

    await tflite.loadModel();
    ref.read(isModelLoadedProvider.notifier).state = true;

    await camera.initialize((CameraImage image) async {
      final isProcessing = ref.read(isProcessingProvider);
      final isModelLoaded = ref.read(isModelLoadedProvider);

      if (!isProcessing && isModelLoaded) {
        ref.read(isProcessingProvider.notifier).state = true;
        final result = await tflite.runInference(image);

        if (mounted) {
          if (result != null) {
            ref.read(predictionProvider.notifier).state =
                PredictionResult.fromMap(result);
          }
          ref.read(isProcessingProvider.notifier).state = false;
        }
      }
    });

    if (!camera.isInitialized) {
      ref.read(hasErrorProvider.notifier).state = true;
      ref.read(errorMessageProvider.notifier).state =
          "Error: Acceso a cámara denegado.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = ref.watch(hasErrorProvider);
    final errorMsg = ref.watch(errorMessageProvider);
    final camera = ref.watch(cameraServiceProvider);

    if (hasError) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                Text(errorMsg, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _initialize,
                  child: const Text('Reintentar'),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (!camera.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 20),
              Text('Iniciando motores de IA...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Camera Preview
          Positioned.fill(
            child: CameraPreview(camera.controller!),
          ),

          // Glassmorphic Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFFFC107)),
                    const SizedBox(width: 10),
                    Text(
                      'MANGO AI DETECTOR',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Result Overlay
          const ResultOverlay(),

          // Bottom Controls / Console
          const Align(
            alignment: Alignment.bottomCenter,
            child: DebugConsole(),
          ),
        ],
      ),
    );
  }
}
