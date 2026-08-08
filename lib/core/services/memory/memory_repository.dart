import 'dart:convert';

import '../../database/business_data.dart';
import '../../models/memory_entry.dart';
import '../../models/user_profile_field.dart';
import '../json_blob_store.dart';

/// Write-path entry point for memory system V1 (§13.4).
///
/// Every mutation is a full-table read-modify-write through
/// [BusinessPreferences] → [BusinessRepository.synchronizeEntities], so
/// payload and derived typed columns stay in the same transaction.
class MemoryRepository extends JsonBlobStore<MemoryEntry> {
  MemoryRepository(super.preferences);

  static final String _memoriesKey = BusinessEntityKind.memoryEntry.sourceKey;
  static final String _profileKey =
      BusinessEntityKind.userProfileField.sourceKey;
  static final String _assistantsKey = BusinessEntityKind.assistant.sourceKey;

  @override
  String get storageKey => _memoriesKey;

  @override
  MemoryEntry decodeItem(Map<String, dynamic> json) =>
      MemoryEntry.fromPayload(json);

  @override
  Map<String, dynamic> encodeItem(MemoryEntry item) => item.toPayload();

  Future<MemoryEntry> create({
    required MemoryScope scope,
    String? assistantId,
    required MemoryType type,
    required String content,
    required MemorySource source,
    List<String> relatedIds = const [],
  }) {
    return runExclusive(() async {
      if (scope == MemoryScope.global && assistantId != null) {
        throw ArgumentError.value(
          assistantId,
          'assistantId',
          'Must be null when scope is global',
        );
      }
      if (scope == MemoryScope.assistant &&
          (assistantId == null || assistantId.isEmpty)) {
        throw ArgumentError.value(
          assistantId,
          'assistantId',
          'Required when scope is assistant',
        );
      }
      final all = await readAll();
      final taken = {for (final entry in all) entry.id};
      var id = MemoryEntry.newId();
      // Random ids collide occasionally; retry rather than fail the write.
      for (var attempt = 0; taken.contains(id) && attempt < 16; attempt++) {
        id = MemoryEntry.newId();
      }
      if (taken.contains(id)) throw StateError('memory_id_collision');
      final now = DateTime.now().toUtc();
      final entry = MemoryEntry(
        id: id,
        scope: scope,
        assistantId: assistantId,
        type: type,
        status: MemoryStatus.active,
        content: content,
        source: source,
        relatedIds: List<String>.of(relatedIds),
        createdAt: now,
        updatedAt: now,
      );
      all.add(entry);
      await writeAll(all);
      return entry;
    });
  }

  Future<MemoryEntry?> updateContent(String id, String content) {
    return runExclusive(() async {
      final all = await readAll();
      final index = all.indexWhere((entry) => entry.id == id);
      if (index == -1) return null;
      final updated = all[index].copyWith(
        content: content,
        updatedAt: DateTime.now().toUtc(),
      );
      all[index] = updated;
      await writeAll(all);
      return updated;
    });
  }

  /// Move an entry between global and an assistant scope (§14.2 scope badge).
  Future<MemoryEntry?> updateScope(
    String id, {
    required MemoryScope scope,
    String? assistantId,
  }) {
    return runExclusive(() async {
      if (scope == MemoryScope.global && assistantId != null) {
        throw ArgumentError.value(
          assistantId,
          'assistantId',
          'Must be null when scope is global',
        );
      }
      if (scope == MemoryScope.assistant &&
          (assistantId == null || assistantId.isEmpty)) {
        throw ArgumentError.value(
          assistantId,
          'assistantId',
          'Required when scope is assistant',
        );
      }
      final all = await readAll();
      final index = all.indexWhere((entry) => entry.id == id);
      if (index == -1) return null;
      final updated = all[index].copyWith(
        scope: scope,
        assistantId: assistantId,
        clearAssistantId: scope == MemoryScope.global,
        updatedAt: DateTime.now().toUtc(),
      );
      all[index] = updated;
      await writeAll(all);
      return updated;
    });
  }

  /// Soft-delete (model `memory_delete` / CONFLICT). Also strips reverse
  /// `relatedIds` references from every other entry in the same write (D-25).
  Future<bool> archive(String id) {
    return runExclusive(() async {
      final all = await readAll();
      final index = all.indexWhere((entry) => entry.id == id);
      if (index == -1) return false;
      if (all[index].status == MemoryStatus.archived) {
        _stripReverseRelatedIds(all, id);
        await writeAll(all);
        return true;
      }
      all[index] = all[index].copyWith(
        status: MemoryStatus.archived,
        updatedAt: DateTime.now().toUtc(),
      );
      _stripReverseRelatedIds(all, id);
      await writeAll(all);
      return true;
    });
  }

  Future<bool> restore(String id) {
    return runExclusive(() async {
      final all = await readAll();
      final index = all.indexWhere((entry) => entry.id == id);
      if (index == -1) return false;
      if (all[index].status == MemoryStatus.active) return true;
      all[index] = all[index].copyWith(
        status: MemoryStatus.active,
        updatedAt: DateTime.now().toUtc(),
      );
      await writeAll(all);
      return true;
    });
  }

  /// Hard-delete (UI only). Also strips reverse `relatedIds` in the same
  /// write (D-25).
  Future<bool> hardDelete(String id) {
    return runExclusive(() async {
      final all = await readAll();
      final before = all.length;
      all.removeWhere((entry) => entry.id == id);
      if (all.length == before) return false;
      _stripReverseRelatedIds(all, id);
      await writeAll(all);
      return true;
    });
  }

  Future<int> hardDeleteMany(List<String> ids) {
    return runExclusive(() async {
      if (ids.isEmpty) return 0;
      final remove = ids.toSet();
      final all = await readAll();
      final before = all.length;
      all.removeWhere((entry) => remove.contains(entry.id));
      final deleted = before - all.length;
      if (deleted == 0) return 0;
      for (final id in remove) {
        _stripReverseRelatedIds(all, id);
      }
      await writeAll(all);
      return deleted;
    });
  }

  /// Idempotent bidirectional `relatedIds` link (D-25).
  ///
  /// Deliberately leaves `updatedAt` alone: `relatedIds` never reaches the
  /// injected block (§7.2), so bumping the entry date here would change the
  /// snapshot hash and force a pointless full re-injection.
  Future<void> linkBidirectional(String a, String b) {
    return runExclusive(() async {
      if (a == b) return;
      final all = await readAll();
      final indexA = all.indexWhere((entry) => entry.id == a);
      final indexB = all.indexWhere((entry) => entry.id == b);
      if (indexA == -1 || indexB == -1) return;

      var changed = false;
      final entryA = all[indexA];
      final entryB = all[indexB];
      if (!entryA.relatedIds.contains(b)) {
        all[indexA] = entryA.copyWith(relatedIds: [...entryA.relatedIds, b]);
        changed = true;
      }
      if (!entryB.relatedIds.contains(a)) {
        all[indexB] = entryB.copyWith(relatedIds: [...entryB.relatedIds, a]);
        changed = true;
      }
      if (changed) await writeAll(all);
    });
  }

  /// Hard-deletes assistant-scoped entries whose assistant no longer exists,
  /// cleaning reverse `relatedIds` in the same write.
  Future<int> deleteOrphanAssistantMemories() {
    return runExclusive(() async {
      final assistantIds = await _readAssistantIds();
      final all = await readAll();
      final orphanIds = <String>{
        for (final entry in all)
          if (entry.scope == MemoryScope.assistant &&
              (entry.assistantId == null ||
                  !assistantIds.contains(entry.assistantId)))
            entry.id,
      };
      if (orphanIds.isEmpty) return 0;
      all.removeWhere((entry) => orphanIds.contains(entry.id));
      for (final id in orphanIds) {
        _stripReverseRelatedIds(all, id);
      }
      await writeAll(all);
      return orphanIds.length;
    });
  }

  Future<void> putProfileField(String key, String value, MemorySource source) {
    return runExclusive(() async {
      if (!UserProfileField.isValidKey(key)) {
        throw ArgumentError.value(key, 'key', 'Invalid profile field key');
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError.value(
          value,
          'value',
          'Empty value clears a field; use removeProfileField',
        );
      }
      final fields = await _readProfileFields();
      final index = fields.indexWhere((field) => field.key == key);
      final next = UserProfileField(
        key: key,
        value: trimmed,
        source: source,
        updatedAt: DateTime.now().toUtc(),
      );
      if (index == -1) {
        fields.add(next);
      } else {
        fields[index] = next;
      }
      await _writeProfileFields(fields);
    });
  }

  Future<bool> removeProfileField(String key) {
    return runExclusive(() async {
      final fields = await _readProfileFields();
      final before = fields.length;
      fields.removeWhere((field) => field.key == key);
      if (fields.length == before) return false;
      await _writeProfileFields(fields);
      return true;
    });
  }

  static void _stripReverseRelatedIds(List<MemoryEntry> all, String targetId) {
    for (var i = 0; i < all.length; i++) {
      final entry = all[i];
      if (!entry.relatedIds.contains(targetId)) continue;
      all[i] = entry.copyWith(
        relatedIds: entry.relatedIds
            .where((id) => id != targetId)
            .toList(growable: false),
      );
    }
  }

  Future<Set<String>> _readAssistantIds() async {
    await preferences.load();
    final raw = preferences.getString(_assistantsKey);
    if (raw == null || raw.isEmpty) return const <String>{};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return {
        for (final item in decoded)
          if (item is Map && item['id'] is String) item['id'] as String,
      };
    } catch (_) {
      throw StateError('json_blob_store_corrupt:$_assistantsKey');
    }
  }

  Future<List<UserProfileField>> _readProfileFields() async {
    await preferences.load();
    final raw = preferences.getString(_profileKey);
    if (raw == null || raw.isEmpty) return <UserProfileField>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in decoded)
          UserProfileField.fromPayload((item as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      throw StateError('json_blob_store_corrupt:$_profileKey');
    }
  }

  Future<void> _writeProfileFields(List<UserProfileField> fields) {
    return preferences.setString(
      _profileKey,
      jsonEncode(fields.map((field) => field.toPayload()).toList()),
    );
  }
}
