import 'package:flutter/foundation.dart';

import '../database/chat_database_repository.dart';
import '../models/memory_entry.dart';
import '../models/user_profile_field.dart';
import '../services/memory/memory_repository.dart';

/// UI-facing ChangeNotifier for memory system V1 (§13.7).
///
/// Intentionally not named [MemoryProvider] — that class remains the legacy
/// read-only store for §14.5. Mixing the two via `context.read` would silently
/// wire the wrong system.
class MemoryProviderV2 extends ChangeNotifier {
  MemoryProviderV2({required this.repository, required this.chatRepository});

  final MemoryRepository repository;
  final ChatDatabaseRepository chatRepository;

  List<MemoryEntry> _entries = const <MemoryEntry>[];
  List<UserProfileField> _profileFields = const <UserProfileField>[];
  int _orphanCount = 0;
  String? _focusAssistantId;
  bool _initialized = false;
  Future<void>? _initializationFuture;

  List<UserProfileField> get profileFields =>
      List<UserProfileField>.unmodifiable(_profileFields);

  int get orphanCount => _orphanCount;

  /// Active memories visible for [assistantId] (global ∪ assistant).
  List<MemoryEntry> visibleFor(String? assistantId) {
    return _entries
        .where(
          (entry) =>
              entry.status == MemoryStatus.active &&
              _isVisible(entry, assistantId),
        )
        .toList(growable: false);
  }

  /// Archived memories visible for [assistantId] (global ∪ assistant).
  List<MemoryEntry> archivedFor(String? assistantId) {
    return _entries
        .where(
          (entry) =>
              entry.status == MemoryStatus.archived &&
              _isVisible(entry, assistantId),
        )
        .toList(growable: false);
  }

  Future<void> initialize({String? assistantId}) {
    if (_initialized && assistantId == _focusAssistantId) {
      return Future<void>.value();
    }
    return _initializationFuture ??= _initialize(assistantId: assistantId);
  }

  Future<void> _initialize({String? assistantId}) async {
    try {
      await refresh(assistantId: assistantId);
      _initialized = true;
    } finally {
      _initializationFuture = null;
    }
  }

  /// Reloads caches from the typed-column read path (§13.1 / §13.3).
  ///
  /// Pass [assistantId] to include that assistant's scoped entries alongside
  /// globals. `null` loads globals only.
  Future<void> refresh({String? assistantId}) async {
    _focusAssistantId = assistantId;
    try {
      final entries = await chatRepository.queryVisibleMemories(
        assistantId: assistantId,
        includeArchived: true,
      );
      final profile = await chatRepository.readProfileFields();
      final orphans = await chatRepository.countOrphanAssistantMemories();
      _entries = entries;
      _profileFields = profile;
      _orphanCount = orphans;
      notifyListeners();
    } catch (e) {
      debugPrint('MemoryProviderV2.refresh failed: $e');
      _entries = const <MemoryEntry>[];
      _profileFields = const <UserProfileField>[];
      _orphanCount = 0;
      notifyListeners();
    }
  }

  Future<MemoryEntry> create({
    required MemoryScope scope,
    String? assistantId,
    required MemoryType type,
    required String content,
    required MemorySource source,
    List<String> relatedIds = const [],
  }) async {
    final entry = await repository.create(
      scope: scope,
      assistantId: assistantId,
      type: type,
      content: content,
      source: source,
      relatedIds: relatedIds,
    );
    await refresh(assistantId: _focusAssistantId);
    return entry;
  }

  Future<MemoryEntry?> updateContent(String id, String content) async {
    final entry = await repository.updateContent(id, content);
    await refresh(assistantId: _focusAssistantId);
    return entry;
  }

  Future<bool> archive(String id) async {
    final ok = await repository.archive(id);
    await refresh(assistantId: _focusAssistantId);
    return ok;
  }

  Future<bool> restore(String id) async {
    final ok = await repository.restore(id);
    await refresh(assistantId: _focusAssistantId);
    return ok;
  }

  Future<bool> hardDelete(String id) async {
    final ok = await repository.hardDelete(id);
    await refresh(assistantId: _focusAssistantId);
    return ok;
  }

  Future<int> hardDeleteMany(List<String> ids) async {
    final count = await repository.hardDeleteMany(ids);
    await refresh(assistantId: _focusAssistantId);
    return count;
  }

  Future<void> linkBidirectional(String a, String b) async {
    await repository.linkBidirectional(a, b);
    await refresh(assistantId: _focusAssistantId);
  }

  Future<int> deleteOrphanAssistantMemories() async {
    final count = await repository.deleteOrphanAssistantMemories();
    await refresh(assistantId: _focusAssistantId);
    return count;
  }

  Future<void> putProfileField(
    String key,
    String value,
    MemorySource source,
  ) async {
    await repository.putProfileField(key, value, source);
    await refresh(assistantId: _focusAssistantId);
  }

  Future<bool> removeProfileField(String key) async {
    final ok = await repository.removeProfileField(key);
    await refresh(assistantId: _focusAssistantId);
    return ok;
  }

  static bool _isVisible(MemoryEntry entry, String? assistantId) {
    if (entry.scope == MemoryScope.global) return true;
    if (assistantId == null) return false;
    return entry.assistantId == assistantId;
  }
}
