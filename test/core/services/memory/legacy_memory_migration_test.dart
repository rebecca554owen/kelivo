import 'package:flutter_test/flutter_test.dart';
import 'package:Kelivo/core/models/memory_entry.dart';
import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/core/services/memory/legacy_memory_migration.dart';
import 'package:Kelivo/core/services/memory/memory_repository.dart';

import '../../../support/business_test_harness.dart';

ProviderConfig _config() => ProviderConfig(
  id: 'test',
  enabled: true,
  name: 'Test',
  apiKey: 'test-key',
  baseUrl: 'https://example.com',
);

void main() {
  group('LegacyMemoryMigrationService', () {
    test('buildPrompt preserves source text as JSON input', () {
      final prompt = LegacyMemoryMigrationService.buildPrompt(
        batch: const [
          LegacyMemoryMigrationInput(
            legacyId: 1,
            assistantId: 'assistant-1',
            content: '用户喜欢“简洁”的回答。',
          ),
        ],
        ids: const [7],
      );

      expect(prompt, contains('Keep the original language.'));
      expect(prompt, contains('用户喜欢'));
      expect(prompt, contains('"id":7'));
    });

    test('parseResponse accepts fenced JSON and restores input order', () {
      final outputs = LegacyMemoryMigrationService.parseResponse(
        '''```json
[
  {"id": 2, "type": "voice", "content": "The user prefers concise replies."},
  {"id": 1, "type": "identity", "content": "The user lives in Tokyo."}
]
```''',
        expectedIds: const [1, 2],
      );

      expect(outputs.map((item) => item.id), [1, 2]);
      expect(outputs.first.type, MemoryType.identity);
      expect(outputs.last.type, MemoryType.voice);
    });

    test('parseResponse rejects missing source items', () {
      expect(
        () => LegacyMemoryMigrationService.parseResponse(
          '[{"id":1,"type":"identity","content":"One"}]',
          expectedIds: const [1, 2],
        ),
        throwsFormatException,
      );
    });

    test(
      'migration id ignores legacy renumbering but tracks stable fields',
      () {
        const original = LegacyMemoryMigrationInput(
          legacyId: 7,
          assistantId: 'assistant-1',
          content: 'Original',
        );
        const edited = LegacyMemoryMigrationInput(
          legacyId: 7,
          assistantId: 'assistant-1',
          content: 'Edited',
        );
        const renumbered = LegacyMemoryMigrationInput(
          legacyId: 99,
          assistantId: 'assistant-1',
          content: 'Original',
        );
        const padded = LegacyMemoryMigrationInput(
          legacyId: 100,
          assistantId: '  assistant-1\n',
          content: '\tOriginal  ',
        );

        final global = LegacyMemoryMigrationService.migrationIdFor(
          input: original,
          target: LegacyMemoryMigrationTarget.global,
        );
        expect(
          LegacyMemoryMigrationService.migrationIdFor(
            input: original,
            target: LegacyMemoryMigrationTarget.global,
          ),
          global,
        );
        expect(
          LegacyMemoryMigrationService.migrationIdFor(
            input: renumbered,
            target: LegacyMemoryMigrationTarget.global,
          ),
          global,
        );
        expect(
          LegacyMemoryMigrationService.migrationIdFor(
            input: padded,
            target: LegacyMemoryMigrationTarget.global,
          ),
          global,
        );
        expect(
          LegacyMemoryMigrationService.migrationIdFor(
            input: edited,
            target: LegacyMemoryMigrationTarget.global,
          ),
          isNot(global),
        );
        final assistant = LegacyMemoryMigrationService.migrationIdFor(
          input: original,
          target: LegacyMemoryMigrationTarget.assistant,
        );
        expect(assistant, isNot(global));
        expect(
          LegacyMemoryMigrationService.migrationIdFor(
            input: padded,
            target: LegacyMemoryMigrationTarget.assistant,
          ),
          assistant,
        );
      },
    );

    test(
      'repeat migration skips model conversion using persisted receipt',
      () async {
        final harness = await createBusinessTestHarness();
        final repository = MemoryRepository(harness.preferences);
        var generatorCalls = 0;
        final service = LegacyMemoryMigrationService(
          repository: repository,
          generateText:
              ({
                required ProviderConfig config,
                required String modelId,
                required String prompt,
                int? thinkingBudget,
              }) async {
                generatorCalls++;
                return '[{"id":1,"type":"identity","content":"Converted"}]';
              },
        );
        const inputs = <LegacyMemoryMigrationInput>[
          LegacyMemoryMigrationInput(
            legacyId: 42,
            assistantId: 'assistant-1',
            content: 'Legacy source',
          ),
        ];

        final first = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
        );
        final second = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
        );

        expect(first.created, 1);
        expect(first.skipped, 0);
        expect(second.created, 0);
        expect(second.skipped, 1);
        expect(generatorCalls, 1);
        final entry = (await repository.readAll()).single;
        expect(
          entry.migrationIds,
          contains(
            LegacyMemoryMigrationService.migrationIdFor(
              input: inputs.single,
              target: LegacyMemoryMigrationTarget.global,
            ),
          ),
        );
      },
    );

    test(
      'content duplicate records receipt and skips model next time',
      () async {
        final harness = await createBusinessTestHarness();
        final repository = MemoryRepository(harness.preferences);
        await repository.create(
          scope: MemoryScope.global,
          type: MemoryType.identity,
          content: 'Already saved',
          source: MemorySource.manual,
        );
        var generatorCalls = 0;
        final service = LegacyMemoryMigrationService(
          repository: repository,
          generateText:
              ({
                required ProviderConfig config,
                required String modelId,
                required String prompt,
                int? thinkingBudget,
              }) async {
                generatorCalls++;
                return '[{"id":1,"type":"identity","content":"Already saved"}]';
              },
        );
        const inputs = <LegacyMemoryMigrationInput>[
          LegacyMemoryMigrationInput(
            legacyId: 9,
            assistantId: 'assistant-1',
            content: 'Old wording',
          ),
        ];

        final first = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
        );
        final second = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
        );

        expect(first.created, 0);
        expect(first.skipped, 1);
        expect(second.skipped, 1);
        expect(generatorCalls, 1);
        final entries = await repository.readAll();
        expect(entries, hasLength(1));
        expect(entries.single.source, MemorySource.manual);
        expect(entries.single.migrationIds, hasLength(1));
      },
    );
  });
}
