import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/remote_connection_provider.dart';

class RemoteConnectScreen extends ConsumerStatefulWidget {
  const RemoteConnectScreen({super.key});

  @override
  ConsumerState<RemoteConnectScreen> createState() =>
      _RemoteConnectScreenState();
}

class _RemoteConnectScreenState extends ConsumerState<RemoteConnectScreen> {
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(remoteConnectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Karrolle'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cast_connected,
              size: 80,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter the IP address shown on your PC',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '192.168.x.x',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            if (connectionState.status == ConnectionStatus.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  connectionState.errorMessage ?? 'Connection failed',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: connectionState.status == ConnectionStatus.connecting
                    ? null
                    : () {
                        final ip = _ipController.text.trim();
                        if (ip.isNotEmpty) {
                          ref
                              .read(remoteConnectionProvider.notifier)
                              .connect(ip);
                        }
                      },
                icon: connectionState.status == ConnectionStatus.connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(
                  connectionState.status == ConnectionStatus.connecting
                      ? 'Connecting...'
                      : 'Connect',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
