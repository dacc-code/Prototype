import 'package:flutter/material.dart';

class ResultOverlay extends StatelessWidget {
  final Map<String, dynamic>? prediction;

  const ResultOverlay({super.key, this.prediction});

  @override
  Widget build(BuildContext context) {
    if (prediction == null) {
      return _buildScanningUI();
    }

    final String label = prediction!['label'];
    final double confidence = prediction!['confidence'];

    // Require at least 60% confidence to show a definitive result
    if (confidence < 0.6) {
      return _buildScanningUI();
    }

    final bool isHealthy = label.toLowerCase() == 'sano';
    final Color color = isHealthy ? Colors.greenAccent : Colors.redAccent;

    return Stack(
      children: [
        // Framing border when detected
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isHealthy ? Icons.check_circle : Icons.warning,
                      color: color,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Confianza: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningUI() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white54, size: 40),
            SizedBox(height: 10),
            Text(
              'Enfoque una hoja clara...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
