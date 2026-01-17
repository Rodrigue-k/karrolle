import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/presentation_engine/presentation/providers/presentation_provider.dart';
import 'features/presentation_engine/presentation/widgets/karrolle_player.dart';
import 'features/presentation_engine/presentation/widgets/remote_server_status_card.dart';
import 'features/remote_control/presentation/screens/remote_control_screen.dart';

void main() {
  runApp(const ProviderScope(child: KarrolleApp()));
}

class KarrolleApp extends StatelessWidget {
  const KarrolleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if running on mobile (Android/iOS) or desktop
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return MaterialApp(
      title: isMobile ? 'Karrolle Remote' : 'Karrolle Presentation Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      home: isMobile ? const RemoteControlScreen() : const KarrolleHomeScreen(),
    );
  }
}

class KarrolleHomeScreen extends ConsumerWidget {
  const KarrolleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentationAsync = ref.watch(presentationProvider);
    final currentScene = ref.watch(currentSceneProvider);

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar for Controls & Server Info
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              border: const Border(right: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Text(
                    'KARROLLE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const RemoteServerStatusCard(),
                const Spacer(),
                if (currentScene != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Scene: ${currentScene.name ?? 'Untitled'}'),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => ref
                                  .read(currentSceneIndexProvider.notifier)
                                  .decrement(),
                              icon: const Icon(Icons.skip_previous),
                            ),
                            IconButton.filledTonal(
                              onPressed: () => ref
                                  .read(currentSceneIndexProvider.notifier)
                                  .increment(),
                              icon: const Icon(Icons.skip_next),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: presentationAsync.when(
              data: (presentation) {
                if (presentation == null || currentScene == null) {
                  return _buildEmptyState();
                }
                return KarrollePlayer(scene: currentScene);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_fill, size: 80, color: Colors.blueAccent),
          SizedBox(height: 20),
          Text(
            'No presentation loaded',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
