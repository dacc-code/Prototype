import 'package:flutter/material.dart';

class ResultOverlay extends StatelessWidget {
  final Map<String, dynamic>? prediction;

  const ResultOverlay({super.key, this.prediction});

  @override
  Widget build(BuildContext context) {
    if (prediction == null) return const SizedBox.shrink();

    final String label = prediction!['label'];
    final double confidence = prediction!['confidence'];
    final bool isHealthy = label.toLowerCase() == 'sano';
    
    final Color color = isHealthy ? Colors.green : Colors.red;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20),
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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confianza: ${(confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
