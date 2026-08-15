import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

import 'package:Kelivo/core/providers/assistant_provider.dart';
import 'package:Kelivo/core/providers/mcp_provider.dart';
import 'package:Kelivo/core/services/mcp/mcp_tool_service.dart';

import '../../../support/business_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'qualifies duplicate tool names and routes each to its server',
    () async {
      final provider = _RecordingMcpProvider([
        McpServerConfig(
          id: 'alpha-id',
          enabled: true,
          name: '123 MCP',
          transport: McpTransportType.http,
          tools: [
            McpToolConfig(enabled: true, name: 'shared'),
            McpToolConfig(enabled: true, name: 'alpha_only'),
          ],
        ),
        McpServerConfig(
          id: 'beta-id',
          enabled: true,
          name: 'Beta MCP',
          transport: McpTransportType.http,
          tools: [
            McpToolConfig(enabled: true, name: 'shared', needsApproval: true),
          ],
        ),
      ]);
      final assistants = AssistantProvider(
        preferences: createBusinessTestPreferences(),
      );
      final service = McpToolService();
      addTearDown(provider.dispose);
      addTearDown(assistants.dispose);
      addTearDown(service.dispose);

      await assistants.loaded;
      final assistantId = await assistants.addAssistant(name: 'Test');
      await assistants.updateAssistant(
        assistants
            .getById(assistantId)!
            .copyWith(mcpServerIds: const ['alpha-id', 'beta-id']),
      );

      final tools = service.listAvailableToolsForAssistant(
        provider,
        assistants,
        assistantId,
      );
      expect(tools.map((tool) => tool.name), [
        'mcp_123_MCP__shared',
        'alpha_only',
        'Beta_MCP__shared',
      ]);
      expect(
        service.toolNeedsApprovalForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'mcp_123_MCP__shared',
        ),
        isFalse,
      );
      expect(
        service.toolNeedsApprovalForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'Beta_MCP__shared',
        ),
        isTrue,
      );

      expect(
        await service.callToolTextForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'mcp_123_MCP__shared',
        ),
        'alpha-id:shared',
      );
      expect(
        await service.callToolTextForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'Beta_MCP__shared',
        ),
        'beta-id:shared',
      );
      expect(provider.calls, [
        (serverId: 'alpha-id', toolName: 'shared'),
        (serverId: 'beta-id', toolName: 'shared'),
      ]);
    },
  );

  test(
    'snapshot keeps names stable but enforces live policy and selection',
    () async {
      final provider = _RecordingMcpProvider([
        McpServerConfig(
          id: 'alpha-id',
          enabled: true,
          name: 'Alpha MCP',
          transport: McpTransportType.http,
          tools: [McpToolConfig(enabled: true, name: 'shared')],
        ),
      ]);
      final assistants = AssistantProvider(
        preferences: createBusinessTestPreferences(),
      );
      final service = McpToolService();
      addTearDown(provider.dispose);
      addTearDown(assistants.dispose);
      addTearDown(service.dispose);

      await assistants.loaded;
      final assistantId = await assistants.addAssistant(name: 'Test');
      await assistants.updateAssistant(
        assistants
            .getById(assistantId)!
            .copyWith(mcpServerIds: const ['alpha-id', 'beta-id']),
      );
      final snapshot = service.captureRoutesForAssistant(
        provider,
        assistants,
        assistantId: assistantId,
      );
      expect(
        service
            .listAvailableToolsForAssistant(provider, assistants, assistantId)
            .single
            .name,
        'shared',
      );

      provider.serversForTest[0] = provider.serversForTest[0].copyWith(
        tools: [
          McpToolConfig(enabled: true, name: 'shared', needsApproval: true),
        ],
      );
      provider.serversForTest.add(
        McpServerConfig(
          id: 'beta-id',
          enabled: true,
          name: 'Beta MCP',
          transport: McpTransportType.http,
          tools: [McpToolConfig(enabled: true, name: 'shared')],
        ),
      );
      expect(
        service
            .listAvailableToolsForAssistant(provider, assistants, assistantId)
            .map((tool) => tool.name),
        ['Alpha_MCP__shared', 'Beta_MCP__shared'],
      );
      expect(
        service.toolNeedsApprovalForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'shared',
          routeSnapshot: snapshot,
        ),
        isTrue,
      );

      expect(
        await service.callToolTextForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'shared',
          routeSnapshot: snapshot,
        ),
        'alpha-id:shared',
      );
      expect(provider.calls, hasLength(1));

      await assistants.updateAssistant(
        assistants
            .getById(assistantId)!
            .copyWith(mcpServerIds: const ['beta-id']),
      );
      expect(
        await service.callToolTextForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'shared',
          routeSnapshot: snapshot,
        ),
        isEmpty,
      );
      expect(provider.calls, hasLength(1));

      await assistants.updateAssistant(
        assistants
            .getById(assistantId)!
            .copyWith(mcpServerIds: const ['alpha-id', 'beta-id']),
      );
      provider.serversForTest[0] = provider.serversForTest[0].copyWith(
        tools: [McpToolConfig(enabled: false, name: 'shared')],
      );
      expect(
        await service.callToolTextForAssistant(
          provider,
          assistants,
          assistantId: assistantId,
          toolName: 'shared',
          routeSnapshot: snapshot,
        ),
        isEmpty,
      );
      expect(provider.calls, hasLength(1));
    },
  );

  test('unavailable tools are not reported as invalid arguments', () async {
    final provider = _RecordingMcpProvider([
      McpServerConfig(
        id: 'server-id',
        enabled: true,
        name: 'Remote MCP',
        transport: McpTransportType.http,
        tools: [
          McpToolConfig(
            enabled: true,
            name: 'get_self',
            schema: const {'type': 'object', 'properties': {}},
          ),
        ],
      ),
    ], errorMessage: 'connection failed');
    final assistants = AssistantProvider(
      preferences: createBusinessTestPreferences(),
    );
    final service = McpToolService();
    addTearDown(provider.dispose);
    addTearDown(assistants.dispose);
    addTearDown(service.dispose);

    await assistants.loaded;
    final assistantId = await assistants.addAssistant(name: 'Test');
    await assistants.updateAssistant(
      assistants
          .getById(assistantId)!
          .copyWith(mcpServerIds: const ['server-id']),
    );

    final output = await service.callToolTextForAssistant(
      provider,
      assistants,
      assistantId: assistantId,
      toolName: 'get_self',
    );
    final error = jsonDecode(output) as Map<String, dynamic>;

    expect(error['error'], 'tool_unavailable');
    expect(error['message'], 'connection failed');
    expect(error, isNot(contains('lastArguments')));
    expect(error, isNot(contains('parametersSchema')));
    expect(error, isNot(contains('instruction')));
  });
}

class _RecordingMcpProvider extends McpProvider {
  _RecordingMcpProvider(this._servers, {this.errorMessage})
    : super(preferences: createBusinessTestPreferences());

  final List<McpServerConfig> _servers;
  final String? errorMessage;
  final List<({String serverId, String toolName})> calls = [];

  List<McpServerConfig> get serversForTest => _servers;

  @override
  List<McpServerConfig> get servers => List.unmodifiable(_servers);

  @override
  Future<void> connect(String id) async {}

  @override
  String? errorFor(String id) => errorMessage ?? super.errorFor(id);

  @override
  Future<mcp.CallToolResult?> callTool(
    String serverId,
    String toolName,
    Map<String, dynamic> args,
  ) async {
    calls.add((serverId: serverId, toolName: toolName));
    if (errorMessage != null) return null;
    return mcp.CallToolResult([mcp.TextContent(text: '$serverId:$toolName')]);
  }
}
