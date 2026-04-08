import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/detection.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final List<Detection> detections;
  final String? imageBase64;

  const ResultScreen({super.key, required this.detections, this.imageBase64});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSending = false;
  String? _sendError;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Resultados del Análisis'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (widget.imageBase64 != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(widget.imageBase64!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: detections.isEmpty
                ? const Center(
                    child: Text('No se detectaron enfermedades'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: detections.length,
                    itemBuilder: (context, index) {
                      final detection = detections[index];
                      final diseaseInfo = DiseaseInfo.getInfo(detection.label);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getColorForSeverity(diseaseInfo.severity),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconForLabel(detection.label),
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          diseaseInfo.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Confianza: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      diseaseInfo.severity.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    diseaseInfo.description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.lightbulb,
                                          color: Colors.blue,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Recomendación',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                diseaseInfo.action,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_sendError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _sendError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sent || _isSending ? null : _sendToApi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sent ? Colors.green : const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(_sent ? Icons.check : Icons.cloud_upload),
                    label: Text(
                      _isSending
                          ? 'Enviando...'
                          : _sent
                              ? 'Enviado al Dashboard'
                              : 'Enviar al Dashboard',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToApi() async {
    setState(() {
      _isSending = true;
      _sendError = null;
    });

    for (final detection in widget.detections) {
      final success = await ApiService.sendDetection(
        detection,
        widget.imageBase64 ?? '',
      );
      
      if (!success) {
        setState(() {
          _sendError = 'Error al enviar detección';
          _isSending = false;
        });
        return;
      }
    }

    setState(() {
      _sent = true;
      _isSending = false;
    });
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'alta':
        return Colors.red.shade700;
      case 'media':
        return Colors.orange.shade700;
      case 'baja':
        return Colors.amber.shade700;
      case 'ninguna':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Dieback-Gall':
        return Icons.warning;
      case 'Black Spots':
        return Icons.blur_on;
      case 'Brown Spots':
        return Icons.grain;
      case 'White Spots':
        return Icons.circle_outlined;
      default:
        return Icons.eco;
    }
  }
}
              itemBuilder: (context, index) {
                final detection = detections[index];
                final diseaseInfo = DiseaseInfo.getInfo(detection.label);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getColorForSeverity(diseaseInfo.severity),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconForLabel(detection.label),
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    diseaseInfo.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Confianza: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                diseaseInfo.severity.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              diseaseInfo.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lightbulb,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Recomendación',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          diseaseInfo.action,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'alta':
        return Colors.red.shade700;
      case 'media':
        return Colors.orange.shade700;
      case 'baja':
        return Colors.amber.shade700;
      case 'ninguna':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'healthy':
        return Icons.check_circle;
      case 'leaf_spot':
        return Icons.blur_on;
      case 'root_rot':
        return Icons.warning;
      case 'yellow_leaf':
        return Icons.wb_sunny;
      case 'brown_spots':
        return Icons.grain;
      case 'leaf_blight':
        return Icons.local_florist;
      default:
        return Icons.help;
    }
  }
}
