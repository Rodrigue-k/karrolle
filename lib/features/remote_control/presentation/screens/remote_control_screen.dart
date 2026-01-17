import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/remote_connection_provider.dart';
import 'remote_connect_screen.dart';

class RemoteControlScreen extends ConsumerWidget {
  const RemoteControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(remoteConnectionProvider);

    // If not connected, show connection screen
    if (connectionState.status != ConnectionStatus.connected) {
      return const RemoteConnectScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Connected: ${connectionState.connectedIp}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off),
            onPressed: () {
              ref.read(remoteConnectionProvider.notifier).disconnect();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scene preview placeholder
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.slideshow, size: 64, color: Colors.white38),
                      SizedBox(height: 8),
                      Text(
                        'Scene Preview',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Control buttons
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: Icons.skip_previous,
                      label: 'Previous',
                      onPressed: () {
                        ref
                            .read(remoteConnectionProvider.notifier)
                            .sendPrevious();
                      },
                    ),
                    _ControlButton(
                      icon: Icons.skip_next,
                      label: 'Next',
                      onPressed: () {
                        ref.read(remoteConnectionProvider.notifier).sendNext();
                      },
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          color: isPrimary ? Colors.blueAccent : Colors.white12,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Icon(
                icon,
                size: 48,
                color: isPrimary ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
