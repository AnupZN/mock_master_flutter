import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../services/manifest_service.dart';
import 'auth_provider.dart';

final manifestServiceProvider = Provider((ref) => ManifestService(ref.read(supabaseProvider)));

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(() {
  return SubjectsNotifier();
});

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    return ref.read(manifestServiceProvider).loadManifest();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(manifestServiceProvider).loadManifest());
  }
}
