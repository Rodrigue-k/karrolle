import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/karrolle_repository_impl.dart';
import '../../domain/models/karrolle_presentation.dart';
import '../../domain/models/karrolle_scene.dart';
import '../../domain/repositories/karrolle_repository.dart';

/// Provider for the repository implementation
final karrolleRepositoryProvider = Provider<KarrolleRepository>((ref) {
  return KarrolleRepositoryImpl();
});

/// Notifier to manage the active presentation
class PresentationNotifier extends Notifier<AsyncValue<KarrollePresentation?>> {
  @override
  AsyncValue<KarrollePresentation?> build() {
    // Start with the sample data for testing
    return AsyncValue.data(KarrollePresentation.sample);
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
