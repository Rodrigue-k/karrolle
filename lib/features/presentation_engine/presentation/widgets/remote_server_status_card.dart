import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/presentation_provider.dart';

class RemoteServerStatusCard extends ConsumerWidget {
  const RemoteServerStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = ref.watch(isServerRunningProvider);
    final ipAsync = ref.watch(serverIpProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.sensors : Icons.sensors_off,
                  color: isRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRunning ? 'Server Active' : 'Server Offline',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: isRunning,
                  onChanged: (value) {
                    if (value) {
                      ref.read(presentationProvider.notifier).startServer();
                    } else {
                      ref.read(presentationProvider.notifier).stopServer();
                    }
                  },
                ),
              ],
            ),
            if (isRunning) ...[
              const Divider(),
              ipAsync.when(
                data: (ip) {
                  if (ip == null) return const Text('IP not found');
                  final connectionUrl = 'karrolle://connect?ip=$ip&port=8080';
                  return Column(
                    children: [
                      Text(
                        'Connect at: $ip:8080',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 10),
                      QrImageView(
                        data: connectionUrl,
                        version: QrVersions.auto,
                        size: 150.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.white,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
