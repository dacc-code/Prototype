import 'package:flutter/material.dart';

class PredictionResult {
  final String label;
  final double confidence;

  PredictionResult({
    required this.label,
    required this.confidence,
  });

  bool get isHealthy => label.toLowerCase() == 'sano';

  Color get color => isHealthy ? Colors.greenAccent : Colors.redAccent;

  factory PredictionResult.fromMap(Map<String, dynamic> map) {
    return PredictionResult(
      label: map['label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
    );
  }
}
