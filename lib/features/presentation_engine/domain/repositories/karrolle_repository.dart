import '../models/karrolle_presentation.dart';

abstract class KarrolleRepository {
  Future<KarrollePresentation> loadPresentation(String path);
  Future<void> savePresentation(KarrollePresentation presentation, String path);
  Future<KarrollePresentation> importFromImages(List<String> imagePaths);
}
