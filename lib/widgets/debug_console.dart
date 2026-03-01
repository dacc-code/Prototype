import 'package:flutter/material.dart';
import '../services/log_service.dart';

class DebugConsole extends StatelessWidget {
  const DebugConsole({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: logger.logs,
      builder: (context, logs, child) {
        if (logs.isEmpty) return const SizedBox.shrink();

        return Container(
          color: Colors.black.withValues(alpha: 0.7),
          padding: const EdgeInsets.all(8.0),
          width: double.infinity,
          height: 200, // Fixed height at the bottom
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debug Console',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete, color: Colors.white, size: 20),
                    onPressed: () => logger.clear(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isError = log.toLowerCase().contains('error') ||
                        log.toLowerCase().contains('exception') ||
                        log.toLowerCase().contains('fail');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        log,
                        style: TextStyle(
                          color:
                              isError ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
