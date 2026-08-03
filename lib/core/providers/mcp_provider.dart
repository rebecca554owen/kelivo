import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;
import '../database/business_preferences.dart';
import '../services/mcp/kelivo_fetch/kelivo_fetch_server.dart';
import '../services/mcp/stdio_command_resolver.dart';
import 'package:uuid/uuid.dart';

/// Transport type: SSE, Streamable HTTP, and STDIO (desktop-only).
enum McpTransportType { sse, http, stdio, inmemory }

/// Connection status for an MCP server.
enum McpStatus { idle, connecting, connected, error }

class _Cooldown {
  final DateTime startedAt;
  final DateTime until;

  const _Cooldown({required this.startedAt, required this.until});
}

class _ServerConnection {
  mcp.Client? client;
  Future<bool>? connectFuture;
  int generation = 0;
  McpStatus status = McpStatus.idle;
  String? error;
  _Cooldown? cooldown;
  Future<void>? refreshFuture;
  bool refreshDirty = false;
}

enum _ToolRefreshOutcome { success, sessionExpired, failed }

class McpParamSpec {
  final String name;
  final bool required;
  final String? type;
  final dynamic defaultValue;

  McpParamSpec({
    required this.name,
    required this.required,
    this.type,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'required': required,
    'type': type,
    'default': defaultValue,
  };

  factory McpParamSpec.fromJson(Map<String, dynamic> json) => McpParamSpec(
    name: json['name'] as String? ?? '',
    required: json['required'] as bool? ?? false,
    type: json['type'] as String?,
    defaultValue: json['default'],
  );
}

class McpToolConfig {
  final bool enabled;
  final String name;
  final String? description;
  final List<McpParamSpec> params;
  // Raw JSON schema for parameters, if provided by the server
  final Map<String, dynamic>? schema;

  /// Whether this tool requires user approval before execution.
  final bool needsApproval;

  McpToolConfig({
    required this.enabled,
    required this.name,
    this.description,
    this.params = const [],
    this.schema,
    this.needsApproval = false,
  });

  McpToolConfig copyWith({
    bool? enabled,
    String? name,
    String? description,
    List<McpParamSpec>? params,
    Map<String, dynamic>? schema,
    bool? needsApproval,
  }) => McpToolConfig(
    enabled: enabled ?? this.enabled,
    name: name ?? this.name,
    description: description ?? this.description,
    params: params ?? this.params,
    schema: schema ?? this.schema,
    needsApproval: needsApproval ?? this.needsApproval,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'name': name,
    'description': description,
    'params': params.map((e) => e.toJson()).toList(),
    if (schema != null) 'schema': schema,
    if (needsApproval) 'needsApproval': true,
  };

  factory McpToolConfig.fromJson(Map<String, dynamic> json) => McpToolConfig(
    enabled: json['enabled'] as bool? ?? true,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    params:
        (json['params'] as List?)
            ?.map(
              (e) => McpParamSpec.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    schema: (json['schema'] is Map)
        ? (json['schema'] as Map).cast<String, dynamic>()
        : null,
    needsApproval: json['needsApproval'] as bool? ?? false,
  );
}

class McpServerConfig {
  final String id; // stable id
  final bool enabled;
  final String name;
  final McpTransportType transport;
  // For SSE/HTTP
  final String url; // SSE endpoint or HTTP base URL
  final List<McpToolConfig> tools;
  final Map<String, String> headers; // custom HTTP headers
  // For STDIO (desktop-only)
  final String? command;
  final List<String> args;
  final Map<String, String> env;
  final String? workingDirectory;

  McpServerConfig({
    required this.id,
    required this.enabled,
    required this.name,
    required this.transport,
    this.url = '',
    this.tools = const [],
    this.headers = const {},
    this.command,
    this.args = const [],
    this.env = const {},
    this.workingDirectory,
  });

  McpServerConfig copyWith({
    String? id,
    bool? enabled,
    String? name,
    McpTransportType? transport,
    String? url,
    List<McpToolConfig>? tools,
    Map<String, String>? headers,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? workingDirectory,
    bool clearWorkingDirectory = false,
  }) => McpServerConfig(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    name: name ?? this.name,
    transport: transport ?? this.transport,
    url: url ?? this.url,
    tools: tools ?? this.tools,
    headers: headers ?? this.headers,
    command: command ?? this.command,
    args: args ?? this.args,
    env: env ?? this.env,
    workingDirectory: clearWorkingDirectory
        ? null
        : (workingDirectory ?? this.workingDirectory),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'enabled': enabled,
    'name': name,
    'transport': transport.name,
    if (transport != McpTransportType.stdio &&
        transport != McpTransportType.inmemory)
      'url': url,
    'tools': tools.map((e) => e.toJson()).toList(),
    if (transport != McpTransportType.stdio &&
        transport != McpTransportType.inmemory)
      'headers': headers,
    if (transport == McpTransportType.stdio) 'command': command,
    if (transport == McpTransportType.stdio) 'args': args,
    if (transport == McpTransportType.stdio) 'env': env,
    if (transport == McpTransportType.stdio && workingDirectory != null)
      'workingDirectory': workingDirectory,
  };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    final tRaw = (json['transport'] as String?) ?? '';
    final t = tRaw == 'http'
        ? McpTransportType.http
        : (tRaw == 'stdio'
              ? McpTransportType.stdio
              : (tRaw == 'inmemory'
                    ? McpTransportType.inmemory
                    : McpTransportType.sse));
    final tools =
        (json['tools'] as List?)
            ?.map(
              (e) => McpToolConfig.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList() ??
        const <McpToolConfig>[];
    if (t == McpTransportType.stdio) {
      final argsAny = json['args'];
      final envAny = json['env'];
      return McpServerConfig(
        id: json['id'] as String? ?? const Uuid().v4(),
        enabled: json['enabled'] as bool? ?? true,
        name: json['name'] as String? ?? '',
        transport: McpTransportType.stdio,
        tools: tools,
        command: (json['command'] as String?)?.trim(),
        args: argsAny is List
            ? argsAny.map((e) => e.toString()).toList()
            : const <String>[],
        env: envAny is Map
            ? envAny.map((k, v) => MapEntry(k.toString(), v.toString()))
            : const <String, String>{},
        workingDirectory: (json['workingDirectory'] as String?)?.trim(),
      );
    } else if (t == McpTransportType.inmemory) {
      return McpServerConfig(
        id: json['id'] as String? ?? const Uuid().v4(),
        enabled: json['enabled'] as bool? ?? true,
        name: json['name'] as String? ?? '',
        transport: McpTransportType.inmemory,
        tools: tools,
      );
    } else {
      return McpServerConfig(
        id: json['id'] as String? ?? const Uuid().v4(),
        enabled: json['enabled'] as bool? ?? true,
        name: json['name'] as String? ?? '',
        transport: t,
        url: json['url'] as String? ?? '',
        tools: tools,
        headers:
            ((json['headers'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )) ??
            const {},
      );
    }
  }
}

class McpProvider extends ChangeNotifier {
  static const String _prefsKey = 'mcp_servers_v1';
  static const String _prefsTimeoutKey = 'mcp_request_timeout_ms_v1';

  final BusinessPreferences preferences;
  final Map<String, _ServerConnection> _connections = {};
  List<McpServerConfig> _servers = [];
  Future<void> _serverMutationTail = Future<void>.value();
  Duration _requestTimeout = const Duration(seconds: 30);
  bool _disposed = false;
  final McpStdioCommandResolver _stdioCommandResolver =
      McpStdioCommandResolver();

  McpProvider({required this.preferences}) {
    unawaited(_serializeServerMutation(_load));
  }

  List<McpServerConfig> get servers => List.unmodifiable(_servers);
  McpStatus statusFor(String id) => _connections[id]?.status ?? McpStatus.idle;
  String? errorFor(String id) => _connections[id]?.error;
  bool get hasAnyEnabled => _servers.any((s) => s.enabled);
  bool isConnected(String id) {
    final state = _connections[id];
    return state?.client?.isConnected == true &&
        state?.status == McpStatus.connected;
  }

  bool isInCooldown(String id) => _activeCooldown(_connections[id]) != null;
  List<McpServerConfig> get connectedServers => _servers
      .where((s) => statusFor(s.id) == McpStatus.connected)
      .toList(growable: false);
  Duration get requestTimeout => _requestTimeout;
  int get requestTimeoutSeconds => _requestTimeout.inSeconds;

  Future<void> _load() async {
    await preferences.load();
    final timeoutMs = preferences.getInt(_prefsTimeoutKey);
    if (timeoutMs != null && timeoutMs > 0) {
      _requestTimeout = Duration(milliseconds: timeoutMs);
    }
    final raw = preferences.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map(
              (e) =>
                  McpServerConfig.fromJson((e as Map).cast<String, dynamic>()),
            )
            .toList();
        _servers = list;
      } catch (_) {}
    }
    // Ensure built-in @kelivo/fetch is present by default
    final builtin = _builtinFetchServerIfMissing();
    if (builtin != null) {
      final next = <McpServerConfig>[..._servers, builtin];
      await _persistServers(next);
      _servers = next;
    }
    // initialize statuses
    for (final s in _servers) {
      _connections.putIfAbsent(s.id, _ServerConnection.new);
    }
    _notify();

    // Auto-connect enabled servers
    for (final s in _servers.where((e) => e.enabled)) {
      // fire and forget
      unawaited(connect(s.id));
    }
  }

  McpServerConfig? _builtinFetchServerIfMissing() {
    final exists = _servers.any(
      (s) =>
          s.transport == McpTransportType.inmemory ||
          s.name == '@kelivo/fetch' ||
          s.id == 'kelivo_fetch',
    );
    if (exists) return null;
    return McpServerConfig(
      id: 'kelivo_fetch',
      enabled: true,
      name: '@kelivo/fetch',
      transport: McpTransportType.inmemory,
      tools: const <McpToolConfig>[], // will refresh on connect
    );
  }

  Future<void> _persistServers(List<McpServerConfig> servers) async {
    await preferences.setString(
      _prefsKey,
      jsonEncode(servers.map((e) => e.toJson()).toList()),
    );
  }

  Future<T> _serializeServerMutation<T>(Future<T> Function() operation) {
    final result = _serverMutationTail.then((_) => operation());
    _serverMutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<void> _persistTimeout(Duration timeout) async {
    await preferences.setInt(_prefsTimeoutKey, timeout.inMilliseconds);
  }

  /// Export current MCP servers as a user-friendly JSON structure.
  ///
  /// Shape:
  /// {
  ///   "mcpServers": {
  ///     "serverId": {
  ///       "name": "...",
  ///       "type": "streamableHttp" | "sse",
  ///       "description": "",
  ///       "isActive": true/false,
  ///       "baseUrl": "...",
  ///       "headers": { ... }
  ///     },
  ///     ...
  ///   }
  /// }
  String exportServersAsUiJson() {
    // On mobile, skip stdio entries in exported JSON.
    final isDesktop = _isDesktopPlatform();
    final map = <String, dynamic>{
      'mcpServers': {
        for (final s in _servers)
          if (s.transport != McpTransportType.stdio || isDesktop)
            s.id: {
              'name': s.name,
              if (s.transport == McpTransportType.http)
                'type': 'streamableHttp',
              if (s.transport == McpTransportType.sse) 'type': 'sse',
              if (s.transport == McpTransportType.inmemory) 'type': 'inmemory',
              'description': '',
              'isActive': s.enabled,
              if (s.transport != McpTransportType.stdio &&
                  s.transport != McpTransportType.inmemory)
                'baseUrl': s.url,
              if (s.transport != McpTransportType.stdio &&
                  s.transport != McpTransportType.inmemory &&
                  s.headers.isNotEmpty)
                'headers': s.headers,
              // For stdio, include an optional type for compatibility
              if (s.transport == McpTransportType.stdio) 'type': 'stdio',
              // Include command/args/env
              if (s.transport == McpTransportType.stdio &&
                  (s.command ?? '').isNotEmpty)
                'command': s.command,
              if (s.transport == McpTransportType.stdio && s.args.isNotEmpty)
                'args': s.args,
              if (s.transport == McpTransportType.stdio && s.env.isNotEmpty)
                'env': s.env,
              if (s.transport == McpTransportType.stdio)
                ...() {
                  final reg =
                      s.env['NPM_CONFIG_REGISTRY'] ??
                      s.env['npm_config_registry'];
                  return reg != null && reg.isNotEmpty
                      ? {'registryUrl': reg}
                      : <String, dynamic>{};
                }(),
              if (s.transport == McpTransportType.stdio &&
                  (s.workingDirectory ?? '').isNotEmpty)
                'workingDirectory': s.workingDirectory,
            },
      },
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Replace all MCP servers from a JSON string.
  /// Accepts either the UI JSON (with top-level `mcpServers`) or the internal list format.
  Future<void> replaceAllFromJson(String rawJson) async {
    dynamic data;
    try {
      data = jsonDecode(rawJson);
    } catch (e) {
      throw FormatException('Invalid JSON: ${e.toString()}');
    }

    List<McpServerConfig> next = [];
    try {
      Map<String, dynamic>? serversFromMap;
      if (data is Map && data.containsKey('mcpServers')) {
        serversFromMap = (data['mcpServers'] as Map).cast<String, dynamic>();
      } else if (data is Map && data.isNotEmpty) {
        // Allow raw map format: { id: { ... } }
        // Heuristically treat it as mcpServers format when values are maps.
        final ok = data.values.every((v) => v is Map);
        if (ok) serversFromMap = data.cast<String, dynamic>();
      }

      if (serversFromMap != null) {
        final isDesktop = _isDesktopPlatform();
        bool builtinSeen = false;
        bool builtinEnabled = true;
        serversFromMap.forEach((id, cfgAny) {
          if (cfgAny is! Map) return;
          final cfg = cfgAny.cast<String, dynamic>();
          final typeLower = (cfg['type'] ?? '').toString().toLowerCase();
          if (typeLower == 'inmemory') {
            // Built-in @kelivo/fetch control via isActive; ignore name mismatches silently
            builtinSeen = true;
            builtinEnabled = (cfg['isActive'] as bool?) ?? true;
            return;
          }
          final hasStdioShape =
              cfg.containsKey('command') ||
              cfg.containsKey('args') ||
              cfg.containsKey('env') ||
              (cfg['type']?.toString().toLowerCase() == 'stdio');
          if (hasStdioShape) {
            if (!isDesktop) {
              // Mobile: skip stdio entries entirely
              return;
            }
            final enabled = (cfg['isActive'] as bool?) ?? true;
            final name = (cfg['name'] as String?)?.trim();
            final cmd = (cfg['command'] as String?)?.trim();
            if (cmd == null || cmd.isEmpty) {
              // invalid stdio entry without command
              return;
            }
            final argsAny = cfg['args'];
            final envAny = cfg['env'];
            final wd = (cfg['workingDirectory'] as String?)?.trim();
            final registryUrl = (cfg['registryUrl'] as String?)?.trim();
            Map<String, String> env = envAny is Map
                ? envAny.map((k, v) => MapEntry(k.toString(), v.toString()))
                : const <String, String>{};
            if ((registryUrl != null) && registryUrl.isNotEmpty) {
              if (!env.containsKey('NPM_CONFIG_REGISTRY') &&
                  !env.containsKey('npm_config_registry')) {
                env = {...env, 'NPM_CONFIG_REGISTRY': registryUrl};
              }
            }
            next.add(
              McpServerConfig(
                id: id,
                enabled: enabled,
                name: (name == null || name.isEmpty) ? id : name,
                transport: McpTransportType.stdio,
                command: cmd,
                args: argsAny is List
                    ? argsAny.map((e) => e.toString()).toList()
                    : const <String>[],
                env: env,
                workingDirectory: (wd != null && wd.isNotEmpty) ? wd : null,
              ),
            );
            return;
          }

          // SSE/HTTP branch using legacy fields
          final typeRaw = (cfg['type'] ?? '').toString().toLowerCase();
          final transport = (typeRaw.contains('http'))
              ? McpTransportType.http
              : McpTransportType.sse;
          final enabled = (cfg['isActive'] as bool?) ?? true;
          final name = (cfg['name'] as String?)?.trim();
          final url = (cfg['baseUrl'] as String?)?.trim();
          final headersAny = cfg['headers'];
          Map<String, String> headers = const {};
          if (headersAny is Map) {
            headers = headersAny.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            );
          }
          if ((url ?? '').isEmpty) {
            // Skip invalid entries with empty URL
            return;
          }
          next.add(
            McpServerConfig(
              id: id,
              enabled: enabled,
              name: (name == null || name.isEmpty) ? id : name,
              transport: transport,
              url: url!,
              headers: headers,
            ),
          );
        });
        if (builtinSeen) {
          // Append single built-in server with fixed id/name
          next.add(
            McpServerConfig(
              id: 'kelivo_fetch',
              enabled: builtinEnabled,
              name: '@kelivo/fetch',
              transport: McpTransportType.inmemory,
            ),
          );
        }
      } else if (data is List) {
        // Attempt to parse internal list format. Be tolerant to transport string variants.
        for (final item in data) {
          if (item is! Map) continue;
          final m = item.cast<String, dynamic>();
          final t = (m['transport'] ?? '').toString().toLowerCase();
          if (t == 'streamablehttp' || t.contains('http')) {
            m['transport'] = 'http';
          } else if (t == 'sse') {
            m['transport'] = 'sse';
          } else if (t == 'stdio') {
            m['transport'] = 'stdio';
          }
          try {
            final s = McpServerConfig.fromJson(m);
            if (s.transport != McpTransportType.stdio &&
                s.transport != McpTransportType.inmemory &&
                s.url.trim().isEmpty) {
              continue;
            }
            next.add(s);
          } catch (_) {}
        }
      } else if (data is Map && data.containsKey('servers')) {
        final list = data['servers'];
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final m = item.cast<String, dynamic>();
            final t = (m['transport'] ?? '').toString().toLowerCase();
            if (t == 'streamablehttp' || t.contains('http')) {
              m['transport'] = 'http';
            } else if (t == 'sse') {
              m['transport'] = 'sse';
            } else if (t == 'stdio') {
              m['transport'] = 'stdio';
            }
            try {
              final s = McpServerConfig.fromJson(m);
              if (s.transport != McpTransportType.stdio &&
                  s.transport != McpTransportType.inmemory &&
                  s.url.trim().isEmpty) {
                continue;
              }
              next.add(s);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      throw FormatException('Unrecognized or invalid MCP JSON');
    }

    if (next.isEmpty) {
      throw FormatException('No valid MCP servers found in JSON');
    }

    await _serializeServerMutation(() async {
      await _persistServers(next);

      // Disconnect all current
      for (final s in _servers) {
        try {
          await disconnect(s.id);
        } catch (_) {}
      }

      // Replace and reset statuses
      _servers = next;
      _connections.clear();
      for (final s in _servers) {
        _connections[s.id] = _ServerConnection();
      }

      _notify();

      // Auto-connect enabled servers
      for (final s in _servers.where((e) => e.enabled)) {
        // fire and forget
        unawaited(connect(s.id));
      }
    });
  }

  McpServerConfig? getById(String id) {
    for (final s in _servers) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<String> addServer({
    required bool enabled,
    required String name,
    required McpTransportType transport,
    String url = '',
    Map<String, String> headers = const {},
    String? command,
    List<String> args = const <String>[],
    Map<String, String> env = const <String, String>{},
    String? workingDirectory,
  }) async {
    final id = const Uuid().v4();
    final cfg = McpServerConfig(
      id: id,
      enabled: enabled,
      name: name.trim().isEmpty ? 'MCP' : name.trim(),
      transport: transport,
      url: url.trim(),
      headers: headers,
      command: command?.trim(),
      args: args,
      env: env,
      workingDirectory: (workingDirectory?.trim().isNotEmpty ?? false)
          ? workingDirectory!.trim()
          : null,
    );
    await _serializeServerMutation(() async {
      final next = <McpServerConfig>[..._servers, cfg];
      await _persistServers(next);
      _servers = next;
      _connections[id] = _ServerConnection();
      _notify();
      if (enabled) {
        unawaited(connect(id));
      }
    });
    return id;
  }

  Future<void> updateServer(McpServerConfig updated) =>
      _updateServer(updated, preserveLatestTools: false);

  Future<void> updateServerMetadata(McpServerConfig updated) =>
      _updateServer(updated, preserveLatestTools: true);

  Future<void> _updateServer(
    McpServerConfig updated, {
    required bool preserveLatestTools,
  }) async {
    await _serializeServerMutation(() async {
      final idx = _servers.indexWhere((e) => e.id == updated.id);
      if (idx < 0) return;
      final next = List<McpServerConfig>.of(_servers)
        ..[idx] = preserveLatestTools
            ? updated.copyWith(tools: _servers[idx].tools)
            : updated;
      await _persistServers(next);
      _servers = next;
      _notify();
      if (!updated.enabled) {
        // The disabled state is already persisted. Tear down the old
        // connection in the background so settings UI does not wait on a
        // remote session DELETE or a connection attempt finishing.
        unawaited(disconnect(updated.id));
      } else {
        // Always reconnect after saving to apply changes (url/transport/name)
        await disconnect(updated.id);
        unawaited(connect(updated.id));
      }
    });
  }

  Future<void> removeServer(String id) async {
    await _serializeServerMutation(() async {
      final next = _servers.where((e) => e.id != id).toList(growable: false);
      await _persistServers(next);
      await disconnect(id);
      _servers = next;
      _connections.remove(id);
      _notify();
    });
  }

  Future<void> reorderServers(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= _servers.length) return;
    if (newIndex < 0 || newIndex >= _servers.length) return;
    final intended = List<McpServerConfig>.of(_servers);
    final moved = intended.removeAt(oldIndex);
    intended.insert(newIndex, moved);
    final predecessorId = newIndex > 0 ? intended[newIndex - 1].id : null;
    final successorId = newIndex + 1 < intended.length
        ? intended[newIndex + 1].id
        : null;
    await _serializeServerMutation(() async {
      final currentOldIndex = _servers.indexWhere(
        (server) => server.id == moved.id,
      );
      if (currentOldIndex < 0) return;
      final next = List<McpServerConfig>.of(_servers);
      final current = next.removeAt(currentOldIndex);
      var insertionIndex = successorId == null
          ? -1
          : next.indexWhere((server) => server.id == successorId);
      if (insertionIndex < 0 && predecessorId != null) {
        final predecessorIndex = next.indexWhere(
          (server) => server.id == predecessorId,
        );
        if (predecessorIndex >= 0) insertionIndex = predecessorIndex + 1;
      }
      if (insertionIndex < 0) {
        insertionIndex = newIndex.clamp(0, next.length);
      }
      next.insert(insertionIndex, current);
      await _persistServers(next);
      _servers = next;
      _notify();
    });
  }

  Future<void> setToolEnabled(
    String serverId,
    String toolName,
    bool enabled,
  ) async {
    await _serializeServerMutation(() async {
      final idx = _servers.indexWhere((e) => e.id == serverId);
      if (idx < 0) return;
      final server = _servers[idx];
      final tools = server.tools
          .map((t) => t.name == toolName ? t.copyWith(enabled: enabled) : t)
          .toList();
      final next = List<McpServerConfig>.of(_servers)
        ..[idx] = server.copyWith(tools: tools);
      await _persistServers(next);
      _servers = next;
      _notify();
    });
  }

  /// Set whether a tool requires user approval before execution.
  Future<void> setToolNeedsApproval(
    String serverId,
    String toolName,
    bool needsApproval,
  ) async {
    await _serializeServerMutation(() async {
      final idx = _servers.indexWhere((e) => e.id == serverId);
      if (idx < 0) return;
      final server = _servers[idx];
      final tools = server.tools
          .map(
            (t) => t.name == toolName
                ? t.copyWith(needsApproval: needsApproval)
                : t,
          )
          .toList();
      final next = List<McpServerConfig>.of(_servers)
        ..[idx] = server.copyWith(tools: tools);
      await _persistServers(next);
      _servers = next;
      _notify();
    });
  }

  /// Conservative: require approval if any enabled cached tool requires it.
  bool toolNeedsApproval(String toolName) {
    for (final s in _servers) {
      if (!s.enabled) continue;
      for (final t in s.tools) {
        if (t.name == toolName && t.enabled && t.needsApproval) return true;
      }
    }
    return false;
  }

  Future<void> connect(String id) async {
    await _connect(id);
  }

  Future<bool> _connect(String id) {
    final server = getById(id);
    if (server == null || !server.enabled || _disposed) {
      return Future<bool>.value(false);
    }
    final state = _connections.putIfAbsent(id, _ServerConnection.new);
    final active = state.connectFuture;
    if (active != null) return active;
    if (_activeCooldown(state) != null) return Future<bool>.value(false);
    if (state.client?.isConnected == true) {
      state.status = McpStatus.connected;
      state.error = null;
      _notify();
      unawaited(refreshTools(id));
      return Future<bool>.value(true);
    }

    return _beginConnect(id, server, state);
  }

  Future<bool> _beginConnect(
    String id,
    McpServerConfig server,
    _ServerConnection state, {
    Future<bool>? waitFor,
  }) {
    state.status = McpStatus.connecting;
    state.error = null;
    final generation = state.generation;
    _notify();
    late final Future<bool> future;
    future =
        (() async {
          if (waitFor != null) {
            try {
              await waitFor;
            } catch (_) {}
          }
          if (_disposed ||
              state.generation != generation ||
              getById(id)?.enabled != true) {
            return false;
          }
          return _performConnect(id, server, state, generation);
        })().whenComplete(() {
          if (identical(state.connectFuture, future)) {
            state.connectFuture = null;
          }
        });
    state.connectFuture = future;
    return future.then((connected) {
      if (connected && !_disposed) unawaited(refreshTools(id));
      return connected;
    });
  }

  Future<bool> _performConnect(
    String id,
    McpServerConfig server,
    _ServerConnection state,
    int generation,
  ) async {
    mcp.Client? client;
    final startedAt = DateTime.now();
    try {
      final clientConfig = mcp.McpClient.simpleConfig(
        name: 'Kelivo MCP',
        version: '1.0.0',
        enableDebugLogging: false,
        requestTimeout: _requestTimeout,
      ).copyWith(maxRetries: 1);

      if (server.transport == McpTransportType.inmemory) {
        client = mcp.McpClient.createClient(clientConfig);
        await client.connect(
          KelivoInMemoryClientTransport(KelivoFetchMcpServerEngine()),
        );
      } else {
        final transportConfig = await _transportConfig(server);
        final result = await mcp.McpClient.createAndConnect(
          config: clientConfig,
          transportConfig: transportConfig,
        );
        client = result.fold((value) => value, (error) => throw error);
      }
      final connectedClient = client;
      if (connectedClient == null) {
        throw StateError('MCP client was not created');
      }

      if (_disposed ||
          state.generation != generation ||
          getById(id)?.enabled != true) {
        await connectedClient.terminateSession();
        connectedClient.dispose();
        return false;
      }

      state.client = connectedClient;
      state.status = McpStatus.connected;
      state.error = null;
      _clearCooldownAfterSuccess(state, startedAt);
      _attachClient(id, state, connectedClient, generation);
      _notify();
      return true;
    } catch (error) {
      client?.dispose();
      if (_disposed || state.generation != generation) return false;
      if (error is mcp.McpHttpError && _requiresCooldown(error)) {
        _enterCooldown(state, error.retryAfter);
      }
      state.status = McpStatus.error;
      state.error = error.toString();
      _notify();
      return false;
    }
  }

  Future<mcp.TransportConfig> _transportConfig(McpServerConfig server) async {
    final headers = server.headers.isEmpty ? null : server.headers;
    if (server.transport == McpTransportType.sse) {
      return mcp.TransportConfig.sse(serverUrl: server.url, headers: headers);
    }
    if (server.transport == McpTransportType.http) {
      return mcp.TransportConfig.streamableHttp(
        baseUrl: server.url,
        headers: headers,
        timeout: _requestTimeout,
        terminateOnClose: false,
      );
    }
    if (!_isDesktopPlatform()) {
      throw StateError('STDIO transport not supported on this platform');
    }
    final command = server.command;
    if (command == null || command.isEmpty) {
      throw StateError('STDIO command is empty');
    }
    final environment = await _stdioCommandResolver.resolveEnvironmentWithPath(
      server.env,
    );
    if (!await _stdioCommandResolver.commandExists(command, environment)) {
      throw StateError(
        'Command "$command" not found in PATH. '
        'Ensure the command is installed and accessible.',
      );
    }
    return mcp.TransportConfig.stdio(
      command: command,
      arguments: server.args,
      workingDirectory: server.workingDirectory,
      environment: environment.isEmpty ? null : environment,
    );
  }

  void _attachClient(
    String id,
    _ServerConnection state,
    mcp.Client client,
    int generation,
  ) {
    client.onDisconnect.listen((_) {
      if (_disposed ||
          state.generation != generation ||
          !identical(state.client, client)) {
        return;
      }
      state.client = null;
      state.status = McpStatus.idle;
      state.error = null;
      _notify();
    });
    client.onError.listen((error) {
      if (_disposed ||
          state.generation != generation ||
          !identical(state.client, client)) {
        return;
      }
      if (error is mcp.McpHttpError &&
          error.isBackgroundRequest &&
          error.statusCode == 404 &&
          error.sessionIdPresent) {
        unawaited(_recoverExpiredSession(id, state, client));
      } else if (error is mcp.McpHttpError && _requiresCooldown(error)) {
        _enterCooldown(state, error.retryAfter);
        _notify();
      } else if (error is mcp.McpHttpError &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        _enterCooldown(state, const Duration(minutes: 5));
        _notify();
      }
    });
    client.onToolsListChanged(() {
      if (_disposed ||
          state.generation != generation ||
          !identical(state.client, client)) {
        return;
      }
      unawaited(refreshTools(id));
    });
  }

  Future<void> updateRequestTimeout(
    Duration duration, {
    bool reconnectActive = true,
  }) async {
    if (duration.inMilliseconds <= 0) return;
    if (duration == _requestTimeout) return;
    await _persistTimeout(duration);
    _requestTimeout = duration;
    _notify();
    if (reconnectActive) {
      for (final state in _connections.values) {
        state.client?.setRequestTimeout(duration);
      }
    }
  }

  Future<void> disconnect(String id, {bool terminateSession = true}) async {
    final state = _connections.putIfAbsent(id, _ServerConnection.new);
    state.generation++;
    final active = state.connectFuture;
    final client = state.client;
    state.client = null;
    state.status = McpStatus.idle;
    state.error = null;
    state.cooldown = null;
    state.refreshDirty = false;
    _notify();

    if (active != null) {
      try {
        await active;
      } catch (_) {}
    }
    if (client != null) {
      if (terminateSession) await client.terminateSession();
      client.dispose();
    }
  }

  Future<bool> reconnect(String id) async {
    if (_activeCooldown(_connections[id]) != null) return false;
    await disconnect(id, terminateSession: true);
    return _connect(id);
  }

  McpToolConfig? _toolConfig(String serverId, String toolName) {
    final idx = _servers.indexWhere((e) => e.id == serverId);
    if (idx < 0) return null;
    final s = _servers[idx];
    for (final t in s.tools) {
      if (t.name == toolName) return t;
    }
    return null;
  }

  Map<String, dynamic> _normalizeArgsForTool(
    String serverId,
    String toolName,
    Map<String, dynamic> args,
  ) {
    try {
      final cfg = _toolConfig(serverId, toolName);
      final schema = cfg?.schema;
      if (schema == null || schema.isEmpty) return args;
      final cloned = jsonDecode(jsonEncode(args)) as Map<String, dynamic>;
      var normalized = _normalizeBySchema(cloned, schema, propertyName: null);
      if (normalized is! Map<String, dynamic>) return args;
      normalized = _normalizeSpecialCases(toolName, normalized);
      return normalized;
    } catch (_) {
      return args;
    }
  }

  Map<String, dynamic> _normalizeSpecialCases(
    String toolName,
    Map<String, dynamic> args,
  ) {
    try {
      if (toolName == 'firecrawl_search') {
        // sources: ["web"] -> [{"type":"web"}]
        final rawSources = args['sources'];
        if (rawSources is List &&
            rawSources.isNotEmpty &&
            rawSources.every((e) => e is String)) {
          args['sources'] = rawSources.map((e) => {'type': e}).toList();
        }
        // Provide pragmatic defaults for commonly required fields if absent
        args.putIfAbsent('tbs', () => '0');
        args.putIfAbsent('filter', () => '0');
        args.putIfAbsent('location', () => 'us');
        // If tbs/filter are present but empty, coerce to '0'
        if ((args['tbs'] is String) && (args['tbs'] as String).isEmpty) {
          args['tbs'] = '0';
        }
        if ((args['filter'] is String) && (args['filter'] as String).isEmpty) {
          args['filter'] = '0';
        }
        if ((args['location'] is String) &&
            (args['location'] as String).toLowerCase() == 'global') {
          args['location'] = 'us';
        }
        final so = (args['scrapeOptions'] is Map)
            ? (args['scrapeOptions'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        so.putIfAbsent('waitFor', () => 0);
        // formats normalization: server expects union of simple literals ["markdown"|"html"|"rawHtml"] OR an object only when type=="json"
        final fm = so['formats'];
        if (fm is List) {
          final norm = <dynamic>[];
          for (final f in fm) {
            if (f is Map) {
              final t = (f['type'] ?? '').toString();
              if (t == 'markdown' || t == 'html' || t == 'rawHtml') {
                norm.add(t);
              } else if (t == 'json') {
                norm.add(f); // keep object form for json
              } else if (t.isNotEmpty) {
                norm.add(t);
              }
            } else if (f is String) {
              if (f == 'json') {
                norm.add({'type': 'json'});
              } else {
                norm.add(f);
              }
            } else {
              norm.add(f);
            }
          }
          so['formats'] = norm;
        }
        args['scrapeOptions'] = so;
      }
    } catch (_) {}
    return args;
  }

  dynamic _normalizeBySchema(
    dynamic value,
    Map<String, dynamic> schema, {
    String? propertyName,
  }) {
    try {
      // Handle anyOf/oneOf by choosing first matching branch; if value is null, attempt defaults
      final List<Map<String, dynamic>> unions = _schemaUnions(schema);
      if (unions.isNotEmpty) {
        // Heuristic only for certain fields (e.g., sources) — DO NOT apply globally.
        if (value is String && propertyName == 'sources') {
          final objBranch = unions.firstWhere(
            (m) =>
                _schemaTypes(m).contains('object') &&
                ((m['properties'] as Map?)?.containsKey('type') ?? false),
            orElse: () => const {},
          );
          if (objBranch.isNotEmpty) {
            return _normalizeBySchema(
              {'type': value},
              objBranch,
              propertyName: propertyName,
            );
          }
        }
        for (final branch in unions) {
          try {
            return _normalizeBySchema(
              value,
              branch,
              propertyName: propertyName,
            );
          } catch (_) {
            // try next branch
          }
        }
        // fallthrough to first branch
        return _normalizeBySchema(
          value,
          unions.first,
          propertyName: propertyName,
        );
      }

      final declaredTypes = _schemaTypes(schema);
      if (declaredTypes.contains('object')) {
        final props =
            (schema['properties'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final req =
            (schema['required'] as List?)?.map((e) => e.toString()).toSet() ??
            const <String>{};
        final out = <String, dynamic>{};
        final input = (value is Map)
            ? value.cast<String, dynamic>()
            : const <String, dynamic>{};
        // copy passthrough unknowns
        input.forEach((k, v) {
          if (!props.containsKey(k)) out[k] = v;
        });
        for (final entry in props.entries) {
          final key = entry.key;
          final propSchema = (entry.value is Map)
              ? (entry.value as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
          dynamic v = input.containsKey(key) ? input[key] : null;
          if (v == null) {
            if (propSchema.containsKey('default')) {
              v = propSchema['default'];
            } else if (req.contains(key)) {
              // Only synthesize enum / waitFor defaults for required fields; optional
              // omitted keys should stay absent (do not pick enum.first).
              final enumVals = _schemaEnum(propSchema);
              if (enumVals.isNotEmpty) {
                v = enumVals.first;
              } else if (key == 'waitFor' &&
                  _schemaTypes(
                    propSchema,
                  ).any((t) => t == 'number' || t == 'integer')) {
                v = 0; // pragmatic default often acceptable for waitFor
              }
            }
          }
          if (v != null) {
            out[key] = _normalizeBySchema(v, propSchema, propertyName: key);
          } else if (!req.contains(key)) {
            // omit optional nulls
          } else {
            // keep as null for required to let server validate if still missing
          }
        }
        return out;
      }

      if (declaredTypes.contains('array')) {
        final items =
            (schema['items'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final list = (value is List) ? value : [value];
        final out = [];
        for (final item in list) {
          dynamic iv = item;
          // Heuristic only for sources array, not for other arrays like formats
          final itemTypes = _schemaTypes(items);
          if (propertyName == 'sources' &&
              item is String &&
              itemTypes.contains('object')) {
            final itemProps =
                (items['properties'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{};
            if (itemProps.containsKey('type')) {
              iv = {'type': item};
            }
          }
          out.add(_normalizeBySchema(iv, items, propertyName: propertyName));
        }
        return out;
      }

      if (declaredTypes.contains('boolean')) {
        if (value is bool) return value;
        if (value is String) {
          final s = value.toLowerCase();
          if (s == 'true' || s == '1' || s == 'yes') return true;
          if (s == 'false' || s == '0' || s == 'no') return false;
        }
        return value;
      }

      if (declaredTypes.contains('integer')) {
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final p = int.tryParse(value);
          if (p != null) return p;
        }
        return value;
      }

      if (declaredTypes.contains('number')) {
        if (value is num) return value;
        if (value is String) {
          final p = double.tryParse(value);
          if (p != null) return p;
        }
        return value;
      }

      if (declaredTypes.contains('string')) {
        if (value == null) return value;
        if (value is String) {
          final enums = _schemaEnum(schema);
          if (enums.isNotEmpty && !enums.contains(value)) {
            // keep original; server will validate
          }
          return value;
        }
        return value.toString();
      }

      // no declared type: return as-is
      return value;
    } catch (_) {
      return value;
    }
  }

  List<Map<String, dynamic>> _schemaUnions(Map<String, dynamic> schema) {
    final out = <Map<String, dynamic>>[];
    final anyOf = schema['anyOf'];
    final oneOf = schema['oneOf'];
    if (anyOf is List) {
      out.addAll(anyOf.whereType<Map>().map((e) => e.cast<String, dynamic>()));
    }
    if (oneOf is List) {
      out.addAll(oneOf.whereType<Map>().map((e) => e.cast<String, dynamic>()));
    }
    return out;
  }

  List<String> _schemaTypes(Map<String, dynamic> schema) {
    final t = schema['type'];
    if (t is String) return [t];
    if (t is List) return t.map((e) => e.toString()).toList();
    return const [];
  }

  List<dynamic> _schemaEnum(Map<String, dynamic> schema) {
    final e = schema['enum'];
    if (e is List) return e;
    return const [];
  }

  Future<void> refreshTools(String id) {
    final state = _connections[id];
    if (state?.client == null || _disposed) return Future<void>.value();
    state!.refreshDirty = true;
    final active = state.refreshFuture;
    if (active != null) return active;

    final future = _drainToolRefresh(id, state);
    state.refreshFuture = future;
    return future.whenComplete(() {
      if (!identical(state.refreshFuture, future)) return;
      state.refreshFuture = null;
      if (state.refreshDirty && !_disposed) {
        unawaited(refreshTools(id));
      }
    });
  }

  Future<void> _drainToolRefresh(String id, _ServerConnection state) async {
    var sessionRecoveries = 0;
    while (state.refreshDirty && !_disposed) {
      state.refreshDirty = false;
      final failedClient = state.client;
      final outcome = await _refreshToolsOnce(id, state);
      if (outcome == _ToolRefreshOutcome.sessionExpired &&
          sessionRecoveries++ == 0 &&
          failedClient != null &&
          await _recoverExpiredSession(id, state, failedClient) != null) {
        state.refreshDirty = true;
        continue;
      }
      if (outcome != _ToolRefreshOutcome.success) return;
    }
  }

  Future<_ToolRefreshOutcome> _refreshToolsOnce(
    String id,
    _ServerConnection state,
  ) async {
    final client = state.client;
    if (client == null) return _ToolRefreshOutcome.failed;
    final generation = state.generation;

    if (client.serverCapabilities?.tools != true) {
      await _persistToolList(id, state, client, const <mcp.Tool>[]);
      if (_disposed ||
          state.generation != generation ||
          !identical(state.client, client)) {
        return _ToolRefreshOutcome.failed;
      }
      state.status = McpStatus.connected;
      state.error = null;
      _notify();
      return _ToolRefreshOutcome.success;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      final cooldown = _activeCooldown(state);
      if (cooldown != null) {
        await Future<void>.delayed(cooldown.until.difference(DateTime.now()));
      }
      if (_disposed ||
          state.generation != generation ||
          !identical(state.client, client)) {
        return _ToolRefreshOutcome.failed;
      }

      final startedAt = DateTime.now();
      try {
        final tools = await client.listTools();
        if (_disposed ||
            state.generation != generation ||
            !identical(state.client, client)) {
          return _ToolRefreshOutcome.failed;
        }
        await _persistToolList(id, state, client, tools);
        if (_disposed ||
            state.generation != generation ||
            !identical(state.client, client)) {
          return _ToolRefreshOutcome.failed;
        }
        state.status = McpStatus.connected;
        state.error = null;
        _clearCooldownAfterSuccess(state, startedAt);
        _notify();
        return _ToolRefreshOutcome.success;
      } catch (error) {
        if (_isRejectedSession(error)) {
          return _ToolRefreshOutcome.sessionExpired;
        }
        if (error is mcp.McpHttpError && _requiresCooldown(error)) {
          _enterCooldown(state, error.retryAfter);
        }
        if (_isSafeTransient(error) && attempt < 2) {
          if (_activeCooldown(state) == null) {
            await Future<void>.delayed(Duration(seconds: attempt == 0 ? 1 : 4));
          }
          continue;
        }
        state.status = McpStatus.error;
        state.error = error.toString();
        _notify();
        return _ToolRefreshOutcome.failed;
      }
    }
    return _ToolRefreshOutcome.failed;
  }

  Future<void> _persistToolList(
    String id,
    _ServerConnection state,
    mcp.Client client,
    List<mcp.Tool> tools,
  ) async {
    await _serializeServerMutation(() async {
      if (!identical(state.client, client)) return;
      final index = _servers.indexWhere((server) => server.id == id);
      if (index < 0) return;
      final existing = {
        for (final tool in _servers[index].tools) tool.name: tool,
      };
      final merged = <McpToolConfig>[];
      for (final tool in tools) {
        final prior = existing[tool.name];
        final params = <McpParamSpec>[];
        final schema = tool.inputSchema;
        final properties =
            (schema['properties'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final required =
            (schema['required'] as List?)?.map((e) => e.toString()).toSet() ??
            const <String>{};
        for (final entry in properties.entries) {
          final value = entry.value is Map
              ? (entry.value as Map).cast<String, dynamic>()
              : const <String, dynamic>{};
          final type = value['type'];
          params.add(
            McpParamSpec(
              name: entry.key,
              required: required.contains(entry.key),
              type: type is List
                  ? type.map((e) => e.toString()).join('|')
                  : type?.toString(),
              defaultValue: value['default'],
            ),
          );
        }
        merged.add(
          McpToolConfig(
            enabled: prior?.enabled ?? true,
            name: tool.name,
            description: tool.description,
            params: params,
            schema: schema,
            needsApproval: prior?.needsApproval ?? false,
          ),
        );
      }
      final next = List<McpServerConfig>.of(_servers)
        ..[index] = _servers[index].copyWith(tools: merged);
      await _persistServers(next);
      _servers = next;
    });
  }

  Future<void> ensureConnected(String id) async {
    // Do not attempt to connect if the server is disabled
    final cfg = getById(id);
    if (cfg == null || !cfg.enabled) return;
    if (isConnected(id)) return;
    await _connect(id);
  }

  Future<mcp.CallToolResult?> callTool(
    String serverId,
    String toolName,
    Map<String, dynamic> args,
  ) async {
    await ensureConnected(serverId);
    final state = _connections[serverId];
    if (state == null) return null;
    final cooldown = _activeCooldown(state);
    if (cooldown != null) {
      return _toolError(
        'MCP server is temporarily unavailable; retry after '
        '${cooldown.until.difference(DateTime.now()).inSeconds + 1} seconds.',
      );
    }
    final client = state.client;
    if (client == null) return null;
    final normalized = _normalizeArgsForTool(serverId, toolName, args);
    final startedAt = DateTime.now();
    try {
      final result = await client.callTool(toolName, normalized);
      _clearCooldownAfterSuccess(state, startedAt);
      return result;
    } catch (error) {
      if (error is mcp.McpError && error.code == -32602) {
        return _toolError(error.toString());
      }
      if (error is mcp.McpHttpError && _requiresCooldown(error)) {
        _enterCooldown(state, error.retryAfter);
        _notify();
        if (error.statusCode == 429) {
          return _toolError('MCP server rate limited this request.');
        }
      }
      if (_isRejectedSession(error)) {
        final replacement = await _recoverExpiredSession(
          serverId,
          state,
          client,
        );
        if (replacement != null) {
          try {
            return await replacement.callTool(toolName, normalized);
          } catch (retryError) {
            if (retryError is mcp.McpHttpError &&
                _requiresCooldown(retryError)) {
              _enterCooldown(state, retryError.retryAfter);
              _notify();
              if (retryError.statusCode == 429) {
                return _toolError('MCP server rate limited this request.');
              }
            }
            if (retryError is mcp.McpError && retryError.code != null) {
              return _toolError(retryError.toString());
            }
            return _toolError(
              'The MCP tool request may have been executed, but its result is '
              'unknown. It was not retried. $retryError',
            );
          }
        }
      }
      if (error is mcp.McpError && error.code != null) {
        return _toolError(error.toString());
      }
      return _toolError(
        'The MCP tool request may have been executed, but its result is '
        'unknown. It was not retried. $error',
      );
    }
  }

  Future<mcp.Client?> _recoverExpiredSession(
    String id,
    _ServerConnection state,
    mcp.Client failedClient,
  ) async {
    if (_disposed || getById(id)?.enabled != true) return null;
    if (!identical(state.client, failedClient)) {
      final active = state.connectFuture;
      if (active != null) {
        try {
          await active;
        } catch (_) {}
      }
      final current = state.client;
      return current?.isConnected == true ? current : null;
    }

    final previousConnect = state.connectFuture;
    state.generation++;
    state.client = null;
    state.status = McpStatus.connecting;
    state.error = null;
    state.cooldown = null;

    final server = getById(id);
    if (server == null || !server.enabled || _disposed) {
      failedClient.dispose();
      return null;
    }
    try {
      final connected = await _beginConnect(
        id,
        server,
        state,
        waitFor: previousConnect,
      );
      await failedClient.waitForPendingRequests();
      return connected ? state.client : null;
    } finally {
      failedClient.dispose();
    }
  }

  _Cooldown? _activeCooldown(_ServerConnection? state) {
    final cooldown = state?.cooldown;
    if (cooldown == null) return null;
    if (!cooldown.until.isAfter(DateTime.now())) {
      state!.cooldown = null;
      return null;
    }
    return cooldown;
  }

  void _enterCooldown(_ServerConnection state, Duration? retryAfter) {
    const minimum = Duration(seconds: 1);
    var delay = retryAfter ?? const Duration(seconds: 30);
    if (delay < minimum) delay = minimum;
    final now = DateTime.now();
    final until = now.add(delay);
    final current = _activeCooldown(state);
    state.cooldown = _Cooldown(
      startedAt: now,
      until: current != null && current.until.isAfter(until)
          ? current.until
          : until,
    );
  }

  void _clearCooldownAfterSuccess(
    _ServerConnection state,
    DateTime requestStartedAt,
  ) {
    final cooldown = state.cooldown;
    if (cooldown == null || !requestStartedAt.isAfter(cooldown.startedAt)) {
      return;
    }
    state.cooldown = null;
  }

  bool _requiresCooldown(mcp.McpHttpError error) =>
      error.statusCode == 429 ||
      (error.statusCode >= 500 && error.retryAfter != null);

  bool _isRejectedSession(Object error) =>
      error is mcp.McpHttpError &&
      error.statusCode == 404 &&
      error.sessionIdPresent &&
      error.canRetryRequest;

  bool _isSafeTransient(Object error) {
    if (error is mcp.McpHttpError) {
      return error.statusCode == 408 ||
          error.statusCode == 429 ||
          error.statusCode >= 500;
    }
    if (error is! mcp.McpError || error.code != null) return false;
    final message = error.message.toLowerCase();
    return message.contains('timed out') ||
        message.contains('transport') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('handshake');
  }

  mcp.CallToolResult _toolError(String message) =>
      mcp.CallToolResult([mcp.TextContent(text: message)], isError: true);

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<McpToolConfig> getEnabledToolsForServers(Set<String> serverIds) {
    final tools = <McpToolConfig>[];
    for (final s in _servers.where((s) => serverIds.contains(s.id))) {
      if (!s.enabled) continue;
      tools.addAll(s.tools.where((t) => t.enabled));
    }
    return tools;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final state in _connections.values) {
      state.generation++;
      state.client?.dispose();
      state.client = null;
    }
    _connections.clear();
    super.dispose();
  }

  bool _isDesktopPlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
