import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../../models/backup.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../chat/chat_service.dart';

class DataSync {
  final ChatService chatService;
  DataSync({required this.chatService});

  // ===== WebDAV helpers =====
  Uri _collectionUri(WebDavConfig cfg) {
    String base = cfg.url.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    String pathPart = cfg.path.trim();
    if (pathPart.isNotEmpty) {
      pathPart = '/${pathPart.replaceAll(RegExp(r'^/+'), '')}';
    }
    // Ensure trailing slash for collection
    final full = '$base$pathPart/';
    return Uri.parse(full);
  }

  Uri _fileUri(WebDavConfig cfg, String childName) {
    final base = _collectionUri(cfg).toString();
    final child = childName.replaceAll(RegExp(r'^/+'), '');
    return Uri.parse('$base$child');
  }

  Map<String, String> _authHeaders(WebDavConfig cfg) {
    if (cfg.username.trim().isEmpty) return {};
    final token = base64Encode(utf8.encode('${cfg.username}:${cfg.password}'));
    return {'Authorization': 'Basic $token'};
  }

  Future<void> _ensureCollection(WebDavConfig cfg) async {
    final client = http.Client();
    try {
      // Ensure each segment exists
      final url = cfg.url.trim().replaceAll(RegExp(r'/+$'), '');
      final segments = cfg.path.split('/').where((s) => s.trim().isNotEmpty).toList();
      String acc = url;
      for (final seg in segments) {
        acc = acc + '/' + seg;
        // PROPFIND depth 0 on this collection (with trailing slash)
        final u = Uri.parse(acc + '/');
        final req = http.Request('PROPFIND', u);
        req.headers.addAll({
          'Depth': '0',
          'Content-Type': 'application/xml; charset=utf-8',
          ..._authHeaders(cfg),
        });
        req.body = '<?xml version="1.0" encoding="utf-8" ?><d:propfind xmlns:d="DAV:"><d:prop><d:displayname/></d:prop></d:propfind>';
        final res = await client.send(req).then(http.Response.fromStream);
        if (res.statusCode == 404) {
          // create this level
          final mk = await client
              .send(http.Request('MKCOL', u)..headers.addAll(_authHeaders(cfg)))
              .then(http.Response.fromStream);
          if (mk.statusCode != 201 && mk.statusCode != 200 && mk.statusCode != 405) {
            throw Exception('MKCOL failed at $u: ${mk.statusCode}');
          }
        } else if (res.statusCode == 401) {
          throw Exception('Unauthorized');
        } else if (!(res.statusCode >= 200 && res.statusCode < 400)) {
          // Some servers return 207 Multi-Status; accept 2xx/3xx/207
          if (res.statusCode != 207) {
            throw Exception('PROPFIND error at $u: ${res.statusCode}');
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // ===== Public APIs =====
  Future<void> testWebdav(WebDavConfig cfg) async {
    final uri = _collectionUri(cfg);
    final req = http.Request('PROPFIND', uri);
    req.headers.addAll({'Depth': '1', 'Content-Type': 'application/xml; charset=utf-8', ..._authHeaders(cfg)});
    req.body = '<?xml version="1.0" encoding="utf-8" ?>\n'
        '<d:propfind xmlns:d="DAV:">\n'
        '  <d:prop>\n'
        '    <d:displayname/>\n'
        '  </d:prop>\n'
        '</d:propfind>';
    final res = await http.Client().send(req).then(http.Response.fromStream);
    if (res.statusCode != 207 && (res.statusCode < 200 || res.statusCode >= 300)) {
      throw Exception('WebDAV test failed: ${res.statusCode}');
    }
  }

  Future<File> prepareBackupFile(WebDavConfig cfg) async {
    final tmp = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outFile = File(p.join(tmp.path, 'kelivo_backup_$timestamp.zip'));
    if (await outFile.exists()) await outFile.delete();

    final encoder = ZipFileEncoder();
    encoder.create(outFile.path);

    // settings.json
    final settingsJson = await _exportSettingsJson();
    encoder.addFile(await _writeTempText('settings.json', settingsJson));

    // chats
    if (cfg.includeChats) {
      final chatsJson = await _exportChatsJson();
      encoder.addFile(await _writeTempText('chats.json', chatsJson));
    }

    // files under upload/
    if (cfg.includeFiles) {
      final uploadDir = await _getUploadDir();
      if (await uploadDir.exists()) {
        final entries = uploadDir.listSync(recursive: true, followLinks: false);
        for (final ent in entries) {
          if (ent is File) {
            final rel = p.relative(ent.path, from: uploadDir.path);
            encoder.addFile(ent, p.join('upload', rel));
          }
        }
      }
    }

    encoder.close();
    return outFile;
  }

  Future<void> backupToWebDav(WebDavConfig cfg) async {
    final file = await prepareBackupFile(cfg);
    await _ensureCollection(cfg);
    final target = _fileUri(cfg, p.basename(file.path));
    final bytes = await file.readAsBytes();
    final res = await http.put(target, headers: {
      'content-type': 'application/zip',
      ..._authHeaders(cfg),
    }, body: bytes);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Upload failed: ${res.statusCode}');
    }
  }

  Future<List<BackupFileItem>> listBackupFiles(WebDavConfig cfg) async {
    await _ensureCollection(cfg);
    final uri = _collectionUri(cfg);
    final req = http.Request('PROPFIND', uri);
    req.headers.addAll({'Depth': '1', 'Content-Type': 'application/xml; charset=utf-8', ..._authHeaders(cfg)});
    req.body = '<?xml version="1.0" encoding="utf-8" ?>\n'
        '<d:propfind xmlns:d="DAV:">\n'
        '  <d:prop>\n'
        '    <d:displayname/>\n'
        '    <d:getcontentlength/>\n'
        '    <d:getlastmodified/>\n'
        '  </d:prop>\n'
        '</d:propfind>';
    final res = await http.Client().send(req).then(http.Response.fromStream);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PROPFIND failed: ${res.statusCode}');
    }
    final doc = XmlDocument.parse(res.body);
    final items = <BackupFileItem>[];
    final baseStr = uri.toString();
    for (final resp in doc.findAllElements('response', namespace: '*')) {
      final href = resp.getElement('href', namespace: '*')?.innerText ?? '';
      if (href.isEmpty) continue;
      // Skip the collection itself
      final abs = Uri.parse(href).isAbsolute ? Uri.parse(href).toString() : uri.resolve(href).toString();
      if (abs == baseStr) continue;
      final disp = resp
              .findAllElements('displayname', namespace: '*')
              .map((e) => e.innerText)
              .toList();
      final sizeStr = resp
          .findAllElements('getcontentlength', namespace: '*')
          .map((e) => e.innerText)
          .cast<String>()
          .toList();
      final mtimeStr = resp
          .findAllElements('getlastmodified', namespace: '*')
          .map((e) => e.innerText)
          .cast<String>()
          .toList();
      final size = (sizeStr.isNotEmpty) ? int.tryParse(sizeStr.first) ?? 0 : 0;
      DateTime? mtime;
      if (mtimeStr.isNotEmpty) {
        try { mtime = DateTime.parse(mtimeStr.first); } catch (_) {}
      }
      final name = (disp.isNotEmpty && disp.first.trim().isNotEmpty)
          ? disp.first.trim()
          : Uri.parse(href).pathSegments.last;
      // Skip directories
      if (abs.endsWith('/')) continue;
      final fullHref = Uri.parse(abs);
      items.add(BackupFileItem(href: fullHref, displayName: name, size: size, lastModified: mtime));
    }
    items.sort((a, b) => (b.lastModified ?? DateTime(0)).compareTo(a.lastModified ?? DateTime(0)));
    return items;
  }

  Future<void> restoreFromWebDav(WebDavConfig cfg, BackupFileItem item) async {
    final res = await http.get(item.href, headers: _authHeaders(cfg));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Download failed: ${res.statusCode}');
    }
    final tmpDir = await getTemporaryDirectory();
    final file = File(p.join(tmpDir.path, item.displayName));
    await file.writeAsBytes(res.bodyBytes);
    await _restoreFromBackupFile(file, cfg);
    try { await file.delete(); } catch (_) {}
  }

  Future<void> deleteWebDavBackupFile(WebDavConfig cfg, BackupFileItem item) async {
    final req = http.Request('DELETE', item.href);
    req.headers.addAll(_authHeaders(cfg));
    final res = await http.Client().send(req).then(http.Response.fromStream);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Delete failed: ${res.statusCode}');
    }
  }

  Future<File> exportToFile(WebDavConfig cfg) => prepareBackupFile(cfg);

  Future<void> restoreFromLocalFile(File file, WebDavConfig cfg) async {
    if (!await file.exists()) throw Exception('备份文件不存在');
    await _restoreFromBackupFile(file, cfg);
  }

  // ===== Internal helpers =====
  Future<File> _writeTempText(String name, String content) async {
    final tmp = await getTemporaryDirectory();
    final f = File(p.join(tmp.path, name));
    await f.writeAsString(content);
    return f;
  }

  Future<Directory> _getUploadDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'upload'));
  }

  Future<String> _exportSettingsJson() async {
    final prefs = await SharedPreferencesAsync.instance;
    final map = await prefs.snapshot();
    return jsonEncode(map);
  }

  Future<String> _exportChatsJson() async {
    if (!chatService.initialized) {
      await chatService.init();
    }
    final conversations = chatService.getAllConversations();
    final allMsgs = <ChatMessage>[];
    final toolEvents = <String, List<Map<String, dynamic>>>{};
    for (final c in conversations) {
      final msgs = chatService.getMessages(c.id);
      allMsgs.addAll(msgs);
      for (final m in msgs) {
        if (m.role == 'assistant') {
          final ev = chatService.getToolEvents(m.id);
          if (ev.isNotEmpty) toolEvents[m.id] = ev;
        }
      }
    }
    final obj = {
      'version': 1,
      'conversations': conversations.map((c) => c.toJson()).toList(),
      'messages': allMsgs.map((m) => m.toJson()).toList(),
      'toolEvents': toolEvents,
    };
    return jsonEncode(obj);
  }

  Future<void> _restoreFromBackupFile(File file, WebDavConfig cfg) async {
    // Extract to temp
    final tmp = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tmp.path, 'restore_${DateTime.now().millisecondsSinceEpoch}'));
    await extractDir.create(recursive: true);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      final outPath = p.join(extractDir.path, entry.name);
      if (entry.isFile) {
        final outFile = File(outPath)..createSync(recursive: true);
        outFile.writeAsBytesSync(entry.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }

    // Restore settings
    final settingsFile = File(p.join(extractDir.path, 'settings.json'));
    if (await settingsFile.exists()) {
      try {
        final txt = await settingsFile.readAsString();
        final map = jsonDecode(txt) as Map<String, dynamic>;
        final prefs = await SharedPreferencesAsync.instance;
        await prefs.restore(map);
      } catch (_) {}
    }

    // Restore chats
    final chatsFile = File(p.join(extractDir.path, 'chats.json'));
    if (cfg.includeChats && await chatsFile.exists()) {
      try {
        final obj = jsonDecode(await chatsFile.readAsString()) as Map<String, dynamic>;
        final convs = (obj['conversations'] as List?)
                ?.map((e) => Conversation.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const <Conversation>[];
        final msgs = (obj['messages'] as List?)
                ?.map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
                .toList() ??
            const <ChatMessage>[];
        final toolEvents = ((obj['toolEvents'] as Map?) ?? const <String, dynamic>{})
            .map((k, v) => MapEntry(k.toString(), (v as List).cast<Map>().map((e) => e.cast<String, dynamic>()).toList()));
        // Clear and restore via ChatService
        await chatService.clearAllData();
        final byConv = <String, List<ChatMessage>>{};
        for (final m in msgs) {
          (byConv[m.conversationId] ??= <ChatMessage>[]).add(m);
        }
        for (final c in convs) {
          final list = byConv[c.id] ?? const <ChatMessage>[];
          await chatService.restoreConversation(c, list);
        }
        // Tool events
        for (final entry in toolEvents.entries) {
          try { await chatService.setToolEvents(entry.key, entry.value); } catch (_) {}
        }
      } catch (_) {}
    }

    // Restore files
    if (cfg.includeFiles) {
      final uploadSrc = Directory(p.join(extractDir.path, 'upload'));
      if (await uploadSrc.exists()) {
        final dst = await _getUploadDir();
        if (await dst.exists()) {
          try { await dst.delete(recursive: true); } catch (_) {}
        }
        await dst.create(recursive: true);
        for (final ent in uploadSrc.listSync(recursive: true)) {
          if (ent is File) {
            final rel = p.relative(ent.path, from: uploadSrc.path);
            final target = File(p.join(dst.path, rel));
            await target.parent.create(recursive: true);
            await ent.copy(target.path);
          }
        }
      }
    }

    try { await extractDir.delete(recursive: true); } catch (_) {}
  }
}

// ===== SharedPreferences async snapshot/restore helpers =====
class SharedPreferencesAsync {
  SharedPreferencesAsync._();
  static SharedPreferencesAsync? _inst;
  static Future<SharedPreferencesAsync> get instance async {
    _inst ??= SharedPreferencesAsync._();
    return _inst!;
  }

  Future<Map<String, dynamic>> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final map = <String, dynamic>{};
    for (final k in keys) {
      map[k] = prefs.get(k);
    }
    return map;
  }

  Future<void> restore(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in data.entries) {
      final k = entry.key;
      final v = entry.value;
      if (v is bool) await prefs.setBool(k, v);
      else if (v is int) await prefs.setInt(k, v);
      else if (v is double) await prefs.setDouble(k, v);
      else if (v is String) await prefs.setString(k, v);
      else if (v is List) {
        await prefs.setStringList(k, v.whereType<String>().toList());
      }
    }
  }
}
