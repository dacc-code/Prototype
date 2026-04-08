import 'package:flutter/material.dart';
import '../models/detection.dart';

class BoundingBoxWidget extends StatelessWidget {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  const BoundingBoxWidget({
    super.key,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoundingBoxPainter(
        detections: detections,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      ),
      size: Size.infinite,
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final detection in detections) {
      final rect = Rect.fromLTWH(
        detection.x * size.width,
        detection.y * size.height,
        detection.width * size.width,
        detection.height * size.height,
      );

      final color = _getColorForLabel(detection.label);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, paint);

      final diseaseInfo = DiseaseInfo.getInfo(detection.label);
      final label = '${diseaseInfo.name} ${(detection.confidence * 100).toStringAsFixed(1)}%';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      final padding = 4.0;
      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - padding * 2,
        textPainter.width + padding * 2,
        textPainter.height + padding * 2,
      );

      final bgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        bgPaint,
      );

      textPainter.paint(canvas, Offset(rect.left + padding, rect.top - textPainter.height - padding));
    }
  }

  Color _getColorForLabel(String label) {
    switch (label) {
      case 'healthy':
        return Colors.green;
      case 'leaf_spot':
        return Colors.orange;
      case 'root_rot':
        return Colors.red;
      case 'yellow_leaf':
        return Colors.yellow.shade700;
      case 'brown_spots':
        return Colors.brown;
      case 'leaf_blight':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return detections != oldDelegate.detections;
  }
}
