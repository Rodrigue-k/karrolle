import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/presentation_engine/presentation/providers/presentation_provider.dart';
import 'features/presentation_engine/presentation/widgets/karrolle_player.dart';

void main() {
  runApp(const ProviderScope(child: KarrolleApp()));
}

class KarrolleApp extends StatelessWidget {
  const KarrolleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karrolle Presentation Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      home: const KarrolleHomeScreen(),
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
      body: presentationAsync.when(
        data: (presentation) {
          if (presentation == null || currentScene == null) {
            return _buildEmptyState();
          }
          return KarrollePlayer(scene: currentScene);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: currentScene != null ? _buildControls(ref) : null,
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
            'KARROLLE',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          Text(
            'No presentation loaded',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () {
            final currentIndex = ref.read(currentSceneIndexProvider);
            if (currentIndex > 0) {
              ref.read(currentSceneIndexProvider.notifier).decrement();
            }
          },
          child: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          onPressed: () {
            final currentIndex = ref.read(currentSceneIndexProvider);
            final presentation = ref.read(presentationProvider).value;
            if (presentation != null &&
                currentIndex < presentation.scenes.length - 1) {
              ref.read(currentSceneIndexProvider.notifier).increment();
            }
          },
          child: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }
}
