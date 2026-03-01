import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/prediction_result.dart';

class ResultOverlay extends ConsumerWidget {
  const ResultOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    final isProcessing = ref.watch(isProcessingProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: prediction == null
          ? _buildScanningUI(isProcessing)
          : _buildResultUI(prediction),
    );
  }

  Widget _buildResultUI(PredictionResult prediction) {
    // Require at least 60% confidence for a definitive result
    if (prediction.confidence < 0.6) {
      return _buildScanningUI(true);
    }

    final color = prediction.color;

    return Stack(
      children: [
        // Framing border with glow
        Container(
          key: const ValueKey('result_border'),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
        ),

        // Result Card
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 100, left: 30, right: 30),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      prediction.isHealthy
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: color,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    prediction.label.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: prediction.confidence,
                      backgroundColor: Colors.white12,
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Confianza del Modelo: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningUI(bool isProcessing) {
    return Center(
      key: const ValueKey('scanning_ui'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScannerFrame(active: isProcessing),
          const SizedBox(height: 30),
          Text(
            isProcessing ? 'ANALIZANDO TEJIDO...' : 'BUSCANDO HOJA...',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatefulWidget {
  final bool active;
  const _ScannerFrame({required this.active});

  @override
  State<_ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<_ScannerFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              // Corner borders
              ..._buildCorners(),
              // Scanning line
              if (widget.active)
                Positioned(
                  top: 250 * _controller.value,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.greenAccent,
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCorners() {
    const double size = 30;
    const double thickness = 4;
    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: Colors.greenAccent,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: Colors.greenAccent,
        ),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: Colors.greenAccent,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: Colors.greenAccent,
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: Colors.greenAccent,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: Colors.greenAccent,
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: Colors.greenAccent,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: Colors.greenAccent,
        ),
      ),
    ];
  }
}
