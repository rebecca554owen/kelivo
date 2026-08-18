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

      expect(prompt, contains('Do not rewrite, translate'));
      expect(prompt, contains('用户喜欢'));
      expect(prompt, contains('"id":7'));
    });

    test('organize-mode prompt still asks the model to keep the language', () {
      final prompt = LegacyMemoryMigrationService.buildPrompt(
        batch: const [
          LegacyMemoryMigrationInput(
            legacyId: 1,
            assistantId: 'assistant-1',
            content: '用户喜欢“简洁”的回答。',
          ),
        ],
        ids: const [7],
        preserveOriginal: false,
      );

      expect(prompt, contains('Keep the original language.'));
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

    test('parseResponse can skip content when expectContent is false', () {
      final outputs = LegacyMemoryMigrationService.parseResponse(
        '[{"id":1,"type":"workflow"}]',
        expectedIds: const [1],
        expectContent: false,
      );
      expect(outputs.single.type, MemoryType.workflow);
      expect(outputs.single.content, isEmpty);
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
          preserveOriginal: false,
        );
        final second = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
          preserveOriginal: false,
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

    test(
      'failed second batch keeps first batch; rerun skips finished work',
      () async {
        final harness = await createBusinessTestHarness();
        final repository = MemoryRepository(harness.preferences);
        final prompts = <String>[];
        final service = LegacyMemoryMigrationService(
          repository: repository,
          batchSize: 1,
          delay: (_) async {},
          generateText:
              ({
                required ProviderConfig config,
                required String modelId,
                required String prompt,
                int? thinkingBudget,
              }) async {
                prompts.add(prompt);
                if (prompt.contains('First memory')) {
                  return '[{"id":1,"type":"identity","content":"Converted first"}]';
                }
                throw const FormatException(
                  'legacy_memory_response_incomplete',
                );
              },
        );
        const inputs = <LegacyMemoryMigrationInput>[
          LegacyMemoryMigrationInput(
            legacyId: 1,
            assistantId: 'assistant-1',
            content: 'First memory',
          ),
          LegacyMemoryMigrationInput(
            legacyId: 2,
            assistantId: 'assistant-1',
            content: 'Second memory',
          ),
        ];

        final first = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
          preserveOriginal: false,
        );
        expect(first.created, 1);
        expect(first.failed, 1);
        expect(first.errorMessage, isNotNull);
        expect((await repository.readAll()).single.content, 'Converted first');
        final callsAfterFirst = prompts.length;
        expect(callsAfterFirst, greaterThan(1));

        final second = await service.migrate(
          inputs: inputs,
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
          preserveOriginal: false,
        );
        expect(second.created, 0);
        expect(second.skipped, 1);
        expect(second.failed, 1);
        expect(prompts.length, greaterThan(callsAfterFirst));
        expect(
          prompts
              .skip(callsAfterFirst)
              .every((p) => !p.contains('First memory')),
          isTrue,
        );
      },
    );

    test('transient batch failure retries then succeeds', () async {
      final harness = await createBusinessTestHarness();
      final repository = MemoryRepository(harness.preferences);
      var attempts = 0;
      var delayed = 0;
      final service = LegacyMemoryMigrationService(
        repository: repository,
        delay: (_) async {
          delayed++;
        },
        generateText:
            ({
              required ProviderConfig config,
              required String modelId,
              required String prompt,
              int? thinkingBudget,
            }) async {
              attempts++;
              if (attempts == 1) {
                throw Exception('network blip');
              }
              return '[{"id":1,"type":"identity","content":"Recovered"}]';
            },
      );

      final result = await service.migrate(
        inputs: const [
          LegacyMemoryMigrationInput(
            legacyId: 1,
            assistantId: 'assistant-1',
            content: 'Retry me',
          ),
        ],
        target: LegacyMemoryMigrationTarget.global,
        config: _config(),
        modelId: 'test-model',
        preserveOriginal: false,
      );

      expect(result.created, 1);
      expect(result.failed, 0);
      expect(attempts, 2);
      expect(delayed, 1);
    });

    test('repeated failure splits the batch and does not throw', () async {
      final harness = await createBusinessTestHarness();
      final repository = MemoryRepository(harness.preferences);
      var calls = 0;
      final service = LegacyMemoryMigrationService(
        repository: repository,
        batchSize: 3,
        delay: (_) async {},
        generateText:
            ({
              required ProviderConfig config,
              required String modelId,
              required String prompt,
              int? thinkingBudget,
            }) async {
              calls++;
              throw const FormatException('legacy_memory_response_incomplete');
            },
      );

      final result = await service.migrate(
        inputs: const [
          LegacyMemoryMigrationInput(
            legacyId: 1,
            assistantId: 'assistant-1',
            content: 'One',
          ),
          LegacyMemoryMigrationInput(
            legacyId: 2,
            assistantId: 'assistant-1',
            content: 'Two',
          ),
          LegacyMemoryMigrationInput(
            legacyId: 3,
            assistantId: 'assistant-1',
            content: 'Three',
          ),
        ],
        target: LegacyMemoryMigrationTarget.global,
        config: _config(),
        modelId: 'test-model',
      );

      expect(result.created, 0);
      expect(result.failed, 3);
      expect(result.errorMessage, isNotNull);
      expect(calls, greaterThan(3));
      expect(await repository.readAll(), isEmpty);
    });

    test(
      'preserve-original stores the legacy text when the model returns type only',
      () async {
        final harness = await createBusinessTestHarness();
        final repository = MemoryRepository(harness.preferences);
        const original = '用户喜欢“简洁”的回答。';
        final service = LegacyMemoryMigrationService(
          repository: repository,
          delay: (_) async {},
          generateText:
              ({
                required ProviderConfig config,
                required String modelId,
                required String prompt,
                int? thinkingBudget,
              }) async {
                expect(prompt, contains('Do not output content'));
                return '[{"id":1,"type":"workflow"}]';
              },
        );

        final result = await service.migrate(
          inputs: const [
            LegacyMemoryMigrationInput(
              legacyId: 8,
              assistantId: 'assistant-1',
              content: original,
            ),
          ],
          target: LegacyMemoryMigrationTarget.global,
          config: _config(),
          modelId: 'test-model',
        );

        expect(result.created, 1);
        expect(result.failed, 0);
        final entry = (await repository.readAll()).single;
        expect(entry.content, original);
        expect(entry.type, MemoryType.workflow);
      },
    );
  });
}
