import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_entry.dart';
import '../services/project_storage_service.dart';

class ProjectListNotifier extends StateNotifier<AsyncValue<List<ProjectEntry>>> {
  ProjectListNotifier() : super(const AsyncValue.loading()) {
    loadProjects();
  }

  final _service = ProjectStorageService.instance;

  Future<void> loadProjects({bool includeTrash = false}) async {
    state = const AsyncValue.loading();
    try {
      final projects = await _service.listProjects(includeTrash: includeTrash);
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProject(String id, {bool permanent = false}) async {
    await _service.deleteProject(id, permanent: permanent);
    await loadProjects();
  }

  Future<void> restoreProject(String id) async {
    await _service.restoreProject(id);
    await loadProjects();
  }

  Future<void> toggleFavorite(String id) async {
    await _service.toggleFavorite(id);
    await loadProjects();
  }
}

final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, AsyncValue<List<ProjectEntry>>>(
      (ref) => ProjectListNotifier(),
    );
