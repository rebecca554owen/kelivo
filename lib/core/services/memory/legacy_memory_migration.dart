import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../models/memory_entry.dart';
import '../../providers/settings_provider.dart';
import '../api/chat_api_service.dart';
import 'memory_repository.dart';
import 'memory_smart_add.dart';

enum LegacyMemoryMigrationTarget { global, assistant }

enum LegacyMemoryMigrationPhase { analyzing, writing }

class LegacyMemoryMigrationInput {
  const LegacyMemoryMigrationInput({
    required this.legacyId,
    required this.assistantId,
    required this.content,
  });

  final int legacyId;
  final String assistantId;
  final String content;
}

class LegacyMemoryMigrationProgress {
  const LegacyMemoryMigrationProgress({
    required this.phase,
    required this.processed,
    required this.total,
  });

  final LegacyMemoryMigrationPhase phase;
  final int processed;
  final int total;

  double get fraction {
    if (total == 0) return 1;
    final phaseOffset = phase == LegacyMemoryMigrationPhase.writing ? total : 0;
    return ((phaseOffset + processed) / (total * 2)).clamp(0, 1).toDouble();
  }
}

class LegacyMemoryMigrationResult {
  const LegacyMemoryMigrationResult({
    required this.created,
    required this.skipped,
  });

  final int created;
  final int skipped;
}

typedef LegacyMemoryTextGenerator =
    Future<String> Function({
      required ProviderConfig config,
      required String modelId,
      required String prompt,
      int? thinkingBudget,
    });

class LegacyMemoryMigrationService {
  LegacyMemoryMigrationService({
    required this.repository,
    LegacyMemoryTextGenerator? generateText,
  }) : _generateText = generateText ?? ChatApiService.generateText;

  static const int batchSize = 12;

  static const String migrationPrompt = '''
You are migrating legacy long-term memories into a typed memory system.

For every input item, return exactly one output item with the same integer id. Preserve every fact, preference, negation, qualification, and uncertainty. Keep the original language. Rewrite only enough to make the memory concise, self-contained, and understandable without conversation context. When appropriate, phrase it as a third-person statement about the user.

Choose exactly one type:
- identity: stable facts, preferences, background, relationships, interests, or personal context
- workflow: recurring ways the user works, decides, plans, or uses tools
- voice: preferred tone, wording, language, formatting, or communication style
- instruction: durable rules for how an assistant should behave or respond

Do not invent, translate, merge, split, omit, deduplicate, explain, or add advice.

Return only a JSON array in this exact shape:
[{"id":1,"type":"identity","content":"..."}]

Input:
{{items}}
''';

  final MemoryRepository repository;
  final LegacyMemoryTextGenerator _generateText;

  Future<LegacyMemoryMigrationResult> migrate({
    required List<LegacyMemoryMigrationInput> inputs,
    required LegacyMemoryMigrationTarget target,
    required ProviderConfig config,
    required String modelId,
    void Function(LegacyMemoryMigrationProgress progress)? onProgress,
  }) async {
    if (inputs.isEmpty) {
      return const LegacyMemoryMigrationResult(created: 0, skipped: 0);
    }

    final existing = await repository.readAll();
    final knownMigrationIds = <String>{
      for (final entry in existing) ...entry.migrationIds,
    };
    final pending = <_PendingLegacyMemory>[];
    var skipped = 0;
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final scope = target == LegacyMemoryMigrationTarget.global
          ? MemoryScope.global
          : MemoryScope.assistant;
      final assistantId = scope == MemoryScope.assistant
          ? input.assistantId
          : null;
      if (scope == MemoryScope.assistant &&
          (assistantId == null || assistantId.trim().isEmpty)) {
        throw const FormatException('legacy_memory_assistant_missing');
      }
      final migrationId = migrationIdFor(input: input, target: target);
      if (knownMigrationIds.contains(migrationId)) {
        skipped++;
        continue;
      }
      pending.add(
        _PendingLegacyMemory(
          promptId: i + 1,
          input: input,
          scope: scope,
          assistantId: assistantId,
          migrationId: migrationId,
        ),
      );
    }

    final converted = <LegacyMemoryMigrationOutput>[];
    onProgress?.call(
      LegacyMemoryMigrationProgress(
        phase: LegacyMemoryMigrationPhase.analyzing,
        processed: skipped,
        total: inputs.length,
      ),
    );

    for (var start = 0; start < pending.length; start += batchSize) {
      final end = start + batchSize < pending.length
          ? start + batchSize
          : pending.length;
      final batch = pending.sublist(start, end);
      final ids = <int>[for (final item in batch) item.promptId];
      final prompt = buildPrompt(
        batch: [for (final item in batch) item.input],
        ids: ids,
      );
      final response = await _generateText(
        config: config,
        modelId: modelId,
        prompt: prompt,
        thinkingBudget: 0,
      );
      converted.addAll(parseResponse(response, expectedIds: ids));
      onProgress?.call(
        LegacyMemoryMigrationProgress(
          phase: LegacyMemoryMigrationPhase.analyzing,
          processed: skipped + end,
          total: inputs.length,
        ),
      );
    }

    onProgress?.call(
      LegacyMemoryMigrationProgress(
        phase: LegacyMemoryMigrationPhase.writing,
        processed: skipped,
        total: inputs.length,
      ),
    );

    final writeResult = await repository.createMany(<MemoryCreateDraft>[
      for (var i = 0; i < converted.length; i++)
        MemoryCreateDraft(
          scope: pending[i].scope,
          assistantId: pending[i].assistantId,
          type: converted[i].type,
          content: converted[i].content,
          source: MemorySource.extracted,
          migrationId: pending[i].migrationId,
        ),
    ]);
    onProgress?.call(
      LegacyMemoryMigrationProgress(
        phase: LegacyMemoryMigrationPhase.writing,
        processed: inputs.length,
        total: inputs.length,
      ),
    );

    return LegacyMemoryMigrationResult(
      created: writeResult.created,
      skipped: skipped + writeResult.skipped,
    );
  }

  static String buildPrompt({
    required List<LegacyMemoryMigrationInput> batch,
    required List<int> ids,
  }) {
    if (batch.length != ids.length) {
      throw ArgumentError('batch and ids must have the same length');
    }
    final items = <Map<String, Object>>[
      for (var i = 0; i < batch.length; i++)
        <String, Object>{'id': ids[i], 'content': batch[i].content},
    ];
    return migrationPrompt.replaceFirst('{{items}}', jsonEncode(items));
  }

  static String migrationIdFor({
    required LegacyMemoryMigrationInput input,
    required LegacyMemoryMigrationTarget target,
  }) {
    final assistantId = input.assistantId.trim();
    final content = input.content.trim();
    final scope = target == LegacyMemoryMigrationTarget.global
        ? MemoryScope.global
        : MemoryScope.assistant;
    final targetAssistantId = scope == MemoryScope.assistant
        ? assistantId
        : null;
    final contentHash = sha256.convert(utf8.encode(content)).toString();
    final identity = jsonEncode(<Object?>[
      assistantId,
      contentHash,
      MemoryEntry.scopeToString(scope),
      targetAssistantId,
    ]);
    return 'legacy_memory_v1:${sha256.convert(utf8.encode(identity))}';
  }

  static List<LegacyMemoryMigrationOutput> parseResponse(
    String response, {
    required List<int> expectedIds,
  }) {
    final decoded = MemorySmartAdd.extractJson(response);
    if (decoded is! List) {
      throw const FormatException('legacy_memory_response_not_array');
    }

    final byId = <int, LegacyMemoryMigrationOutput>{};
    for (final raw in decoded) {
      if (raw is! Map) {
        throw const FormatException('legacy_memory_response_item_invalid');
      }
      final id = switch (raw['id']) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };
      final typeValue = raw['type']?.toString().trim().toLowerCase();
      final content = raw['content']?.toString().trim() ?? '';
      if (id == null || typeValue == null || content.isEmpty) {
        throw const FormatException('legacy_memory_response_item_invalid');
      }
      final type = MemoryEntry.typeFromString(typeValue);
      if (byId.containsKey(id)) {
        throw const FormatException('legacy_memory_response_duplicate_id');
      }
      byId[id] = LegacyMemoryMigrationOutput(
        id: id,
        type: type,
        content: content,
      );
    }

    if (byId.length != expectedIds.length ||
        expectedIds.any((id) => !byId.containsKey(id))) {
      throw const FormatException('legacy_memory_response_incomplete');
    }
    return <LegacyMemoryMigrationOutput>[
      for (final id in expectedIds) byId[id]!,
    ];
  }
}

class _PendingLegacyMemory {
  const _PendingLegacyMemory({
    required this.promptId,
    required this.input,
    required this.scope,
    required this.assistantId,
    required this.migrationId,
  });

  final int promptId;
  final LegacyMemoryMigrationInput input;
  final MemoryScope scope;
  final String? assistantId;
  final String migrationId;
}

class LegacyMemoryMigrationOutput {
  const LegacyMemoryMigrationOutput({
    required this.id,
    required this.type,
    required this.content,
  });

  final int id;
  final MemoryType type;
  final String content;
}
