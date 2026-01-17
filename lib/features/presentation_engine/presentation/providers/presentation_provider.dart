import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:karrolle/features/presentation_engine/data/sources/websocket_server.dart';
import 'package:karrolle/features/presentation_engine/domain/models/remote_command.dart';
import 'package:karrolle/features/presentation_engine/domain/models/karrolle_presentation.dart';
import 'package:karrolle/features/presentation_engine/domain/models/karrolle_scene.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/presentation_engine/domain/repositories/karrolle_repository.dart';
import 'package:karrolle/features/presentation_engine/data/repositories/karrolle_repository_impl.dart';

/// Provider for the repository implementation
final karrolleRepositoryProvider = Provider<KarrolleRepository>((ref) {
  return KarrolleRepositoryImpl();
});

/// Provider for the server instance (singleton)
final serverInstanceProvider = Provider<KarrolleWebSocketServer>((ref) {
  final notifier = ref.read(presentationProvider.notifier);
  return KarrolleWebSocketServer(onCommandReceived: notifier.handleCommand);
});

/// Notifier for server running status
class ServerRunningNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRunning(bool value) => state = value;
}

final isServerRunningProvider = NotifierProvider<ServerRunningNotifier, bool>(
  ServerRunningNotifier.new,
);

/// Notifier to manage the active presentation
class PresentationNotifier extends Notifier<AsyncValue<KarrollePresentation?>> {
  @override
  AsyncValue<KarrollePresentation?> build() {
    // Start with the sample data for testing
    return AsyncValue.data(KarrollePresentation.sample);
  }

  void handleCommand(RemoteCommand command) {
    logger.d('Handling RemoteCommand: ${command.runtimeType}');
    switch (command) {
      case NextCommand():
        final current = ref.read(currentSceneIndexProvider);
        final presentation = state.value;
        if (presentation != null && current < presentation.scenes.length - 1) {
          ref.read(currentSceneIndexProvider.notifier).increment();
        }
      case PreviousCommand():
        final current = ref.read(currentSceneIndexProvider);
        if (current > 0) {
          ref.read(currentSceneIndexProvider.notifier).decrement();
        }
      case GotoCommand(index: final idx):
        final presentation = state.value;
        if (presentation != null &&
            idx >= 0 &&
            idx < presentation.scenes.length) {
          ref.read(currentSceneIndexProvider.notifier).set(idx);
        }
      case PointerCommand():
        break;
      case ZoomCommand():
        break;
    }
  }

  Future<void> startServer() async {
    final server = ref.read(serverInstanceProvider);
    if (server.isRunning) return;

    await server.start();
    ref.read(isServerRunningProvider.notifier).setRunning(true);
  }

  Future<void> stopServer() async {
    final server = ref.read(serverInstanceProvider);
    await server.stop();
    ref.read(isServerRunningProvider.notifier).setRunning(false);
  }

  Future<void> loadPresentation(String path) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(karrolleRepositoryProvider).loadPresentation(path),
    );
  }

  Future<void> importImages(List<String> paths) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(karrolleRepositoryProvider).importFromImages(paths),
    );
  }

  void updatePresentation(KarrollePresentation presentation) {
    state = AsyncValue.data(presentation);
  }
}

final presentationProvider =
    NotifierProvider<PresentationNotifier, AsyncValue<KarrollePresentation?>>(
      PresentationNotifier.new,
    );

/// Provider for server info (IP)
final serverIpProvider = FutureProvider<String?>((ref) async {
  return await NetworkInfo().getWifiIP();
});

class CurrentSceneIndex extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
  void increment() => state++;
  void decrement() => state--;
}

final currentSceneIndexProvider = NotifierProvider<CurrentSceneIndex, int>(
  CurrentSceneIndex.new,
);

/// Provider for the current scene
final currentSceneProvider = Provider<KarrolleScene?>((ref) {
  final presentationAsync = ref.watch(presentationProvider);
  final index = ref.watch(currentSceneIndexProvider);

  return presentationAsync.when(
    data: (p) =>
        (p != null && index < p.scenes.length) ? p.scenes[index] : null,
    loading: () => null,
    error: (error, stack) => null,
  );
});
