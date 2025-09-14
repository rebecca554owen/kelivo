import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/model_provider.dart';
import '../../../icons/lucide_adapter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'model_detail_sheet.dart';
import '../../provider/pages/provider_detail_page.dart';
import '../../../l10n/app_localizations.dart';

class ModelSelection {
  final String providerKey;
  final String modelId;
  ModelSelection(this.providerKey, this.modelId);
}

// Data class for compute function
class _ModelProcessingData {
  final Map<String, dynamic> providerConfigs;
  final Set<String> pinnedModels;
  final String currentModelKey;
  final List<String> providersOrder;
  final String? limitProviderKey;
  
  _ModelProcessingData({
    required this.providerConfigs,
    required this.pinnedModels,
    required this.currentModelKey,
    required this.providersOrder,
    this.limitProviderKey,
  });
}

class _ModelProcessingResult {
  final Map<String, _ProviderGroup> groups;
  final List<_ModelItem> favItems;
  final List<String> orderedKeys;
  
  _ModelProcessingResult({
    required this.groups,
    required this.favItems,
    required this.orderedKeys,
  });
}

// Lightweight brand asset resolver usable in isolates
String? _assetForNameStatic(String n) {
  final lower = n.toLowerCase();
  final mapping = <RegExp, String>{
    RegExp(r'openai|gpt|o\d'): 'openai.svg',
    RegExp(r'gemini'): 'gemini-color.svg',
    RegExp(r'google'): 'google-color.svg',
    RegExp(r'claude'): 'claude-color.svg',
    RegExp(r'anthropic'): 'anthropic.svg',
    RegExp(r'deepseek'): 'deepseek-color.svg',
    RegExp(r'grok'): 'grok.svg',
    RegExp(r'qwen|qwq|qvq|aliyun|dashscope'): 'qwen-color.svg',
    RegExp(r'doubao|ark|volc'): 'doubao-color.svg',
    RegExp(r'openrouter'): 'openrouter.svg',
    RegExp(r'zhipu|智谱|glm'): 'zhipu-color.svg',
    RegExp(r'mistral'): 'mistral-color.svg',
    RegExp(r'(?<!o)llama|meta'): 'meta-color.svg',
    RegExp(r'hunyuan|tencent'): 'hunyuan-color.svg',
    RegExp(r'gemma'): 'gemma-color.svg',
    RegExp(r'perplexity'): 'perplexity-color.svg',
    RegExp(r'aliyun|阿里云|百炼'): 'alibabacloud-color.svg',
    RegExp(r'bytedance|火山'): 'bytedance-color.svg',
    RegExp(r'silicon|硅基'): 'siliconflow-color.svg',
    RegExp(r'aihubmix'): 'aihubmix-color.svg',
    RegExp(r'ollama'): 'ollama.svg',
    RegExp(r'github'): 'github.svg',
    RegExp(r'cloudflare'): 'cloudflare-color.svg',
    RegExp(r'minimax'): 'minimax-color.svg',
    RegExp(r'xai|grok'): 'xai.svg',
    RegExp(r'juhenext'): 'juhenext.png',
    RegExp(r'kimi'): 'kimi-color.svg',
    RegExp(r'302'): '302ai-color.svg',
    RegExp(r'step|阶跃'): 'stepfun-color.svg',
    RegExp(r'intern|书生'): 'internlm-color.svg',
    RegExp(r'cohere|command-.+'): 'cohere-color.svg',
    RegExp(r'kelivo'): 'kelivo.png',
  };
  for (final e in mapping.entries) {
    if (e.key.hasMatch(lower)) return 'assets/icons/${e.value}';
  }
  return null;
}

// Static function for compute - must be top-level
_ModelProcessingResult _processModelsInBackground(_ModelProcessingData data) {
  final providers = data.limitProviderKey == null
      ? data.providerConfigs
      : {
    if (data.providerConfigs.containsKey(data.limitProviderKey))
      data.limitProviderKey!: data.providerConfigs[data.limitProviderKey]!,
  };
  
  // Build data map: providerKey -> (displayName, models)
  final Map<String, _ProviderGroup> groups = {};
  
  providers.forEach((key, cfg) {
    // Skip disabled providers entirely so they can't be selected
    if (!(cfg['enabled'] as bool)) return;
    final models = cfg['models'] as List<dynamic>? ?? [];
    if (models.isEmpty) return;
    
    final name = (cfg['name'] as String?) ?? '';
    final overrides = (cfg['overrides'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? const <String, dynamic>{};
    final list = <_ModelItem>[
      for (final id in models)
        () {
          final String mid = id.toString();
          ModelInfo base = ModelRegistry.infer(ModelInfo(id: mid, displayName: mid));
          final ov = overrides[mid] as Map?;
          if (ov != null) {
            // display name override
            final n = (ov['name'] as String?)?.trim();
            // type override
            ModelType? type;
            final t = (ov['type'] as String?)?.trim();
            if (t != null) {
              type = (t == 'embedding') ? ModelType.embedding : ModelType.chat;
            }
            // modality override
            List<Modality>? input;
            if (ov['input'] is List) {
              input = [
                for (final e in (ov['input'] as List)) (e.toString() == 'image' ? Modality.image : Modality.text)
              ];
            }
            List<Modality>? output;
            if (ov['output'] is List) {
              output = [
                for (final e in (ov['output'] as List)) (e.toString() == 'image' ? Modality.image : Modality.text)
              ];
            }
            List<ModelAbility>? abilities;
            if (ov['abilities'] is List) {
              abilities = [
                for (final e in (ov['abilities'] as List)) (e.toString() == 'reasoning' ? ModelAbility.reasoning : ModelAbility.tool)
              ];
            }
            base = base.copyWith(
              displayName: (n != null && n.isNotEmpty) ? n : base.displayName,
              type: type ?? base.type,
              input: input ?? base.input,
              output: output ?? base.output,
              abilities: abilities ?? base.abilities,
            );
          }
          return _ModelItem(
            providerKey: key,
            providerName: name.isNotEmpty ? name : key,
            id: mid,
            info: base,
            pinned: data.pinnedModels.contains('$key::$mid'),
            selected: data.currentModelKey == '$key::$mid',
            asset: _assetForNameStatic(mid),
          );
        }()
    ];
    groups[key] = _ProviderGroup(name: name.isNotEmpty ? name : key, items: list);
  });
  
  // Build favorites group (duplicate items)
  final favItems = <_ModelItem>[];
  for (final k in data.pinnedModels) {
    final parts = k.split('::');
    if (parts.length < 2) continue;
    final pk = parts[0];
    final mid = parts.sublist(1).join('::');
    final g = groups[pk];
    if (g == null) continue;
    final found = g.items.firstWhere(
      (e) => e.id == mid,
      orElse: () => _ModelItem(
        providerKey: pk,
        providerName: g.name,
        id: mid,
        info: ModelRegistry.infer(ModelInfo(id: mid, displayName: mid)),
        pinned: true,
        selected: data.currentModelKey == '$pk::$mid',
      ),
    );
    favItems.add(found.copyWith(pinned: true));
  }
  
  // Provider sections ordered by ProvidersPage order
  final orderedKeys = <String>[];
  for (final k in data.providersOrder) {
    if (groups.containsKey(k)) orderedKeys.add(k);
  }
  for (final k in groups.keys) {
    if (!orderedKeys.contains(k)) orderedKeys.add(k);
  }
  
  return _ModelProcessingResult(
    groups: groups,
    favItems: favItems,
    orderedKeys: orderedKeys,
  );
}

Future<ModelSelection?> showModelSelector(BuildContext context, {String? limitProviderKey}) async {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<ModelSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ModelSelectSheet(limitProviderKey: limitProviderKey),
  );
}

Future<void> showModelSelectSheet(BuildContext context) async {
  final sel = await showModelSelector(context);
  if (sel != null) {
    // persist as current model
    final settings = context.read<SettingsProvider>();
    await settings.setCurrentModel(sel.providerKey, sel.modelId);
  }
}

class _ModelSelectSheet extends StatefulWidget {
  const _ModelSelectSheet({this.limitProviderKey});
  final String? limitProviderKey;
  @override
  State<_ModelSelectSheet> createState() => _ModelSelectSheetState();
}

class _ModelSelectSheetState extends State<_ModelSelectSheet> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _headers = {};
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  static const double _initialSize = 0.7;
  static const double _maxSize = 0.85;
  ScrollController? _listCtrl; // controller from DraggableScrollableSheet
  final Map<String, double> _providerOffsets = {}; // Store cumulative offset for each provider
  
  // Constants for item heights
  static const double _sectionHeaderHeight = 44.0;
  static const double _modelTileHeight = 68.0;
  
  // Async loading state
  bool _isLoading = true;
  Map<String, _ProviderGroup> _groups = {};
  List<_ModelItem> _favItems = [];
  List<String> _orderedKeys = [];
  bool _autoScrolled = false; // ensure we only auto-scroll once per open

  @override
  void initState() {
    super.initState();
    // Delay loading to allow the sheet to open first
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _loadModelsAsync();
      }
    });
  }

  Future<void> _loadModelsAsync() async {
    try {
      final settings = context.read<SettingsProvider>();
      
      // Prepare data for background processing
      final processingData = _ModelProcessingData(
        providerConfigs: Map<String, dynamic>.from(
          settings.providerConfigs.map((key, value) => MapEntry(key, {
            'enabled': value.enabled,
            'name': value.name,
            'models': value.models,
            'overrides': value.modelOverrides,
          })),
        ),
        pinnedModels: settings.pinnedModels,
        currentModelKey: settings.currentModelKey ?? '',
        providersOrder: settings.providersOrder,
        limitProviderKey: widget.limitProviderKey,
      );
      
      // Process in background isolate
      final result = await compute(_processModelsInBackground, processingData);
      
      if (mounted) {
        setState(() {
          _groups = result.groups;
          _favItems = result.favItems;
          _orderedKeys = result.orderedKeys;
          _isLoading = false;
        });
        _scheduleAutoScrollToCurrent();
      }
    } catch (e) {
      // If compute fails (e.g., on web), fall back to synchronous processing
      if (mounted) {
        _loadModelsSynchronously();
      }
    }
  }
  
  void _loadModelsSynchronously() {
    final settings = context.read<SettingsProvider>();
    final processingData = _ModelProcessingData(
      providerConfigs: Map<String, dynamic>.from(
        settings.providerConfigs.map((key, value) => MapEntry(key, {
          'enabled': value.enabled,
          'name': value.name,
          'models': value.models,
          'overrides': value.modelOverrides,
        })),
      ),
      pinnedModels: settings.pinnedModels,
      currentModelKey: settings.currentModelKey ?? '',
      providersOrder: settings.providersOrder,
      limitProviderKey: widget.limitProviderKey,
    );
    
    final result = _processModelsInBackground(processingData);
    
    setState(() {
      _groups = result.groups;
      _favItems = result.favItems;
      _orderedKeys = result.orderedKeys;
      _isLoading = false;
    });
    _scheduleAutoScrollToCurrent();
  }

  void _scheduleAutoScrollToCurrent() {
    if (_autoScrolled) return;
    // Wait until the content has been laid out and offsets computed in _buildContent
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _autoScrolled) return;
      await _jumpToCurrentSelection();
      _autoScrolled = true;
    });
  }

  Future<void> _jumpToCurrentSelection() async {
    final settings = context.read<SettingsProvider>();
    final pk = settings.currentModelProvider;
    final mid = settings.currentModelId;
    if (pk == null || mid == null) return;

    // Optionally expand a bit for better context
    if (_sheetCtrl.size < _initialSize + 0.05) {
      try {
        await _sheetCtrl.animateTo(
          _initialSize.clamp(0.0, _maxSize),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    }

    // Ensure list controller is ready
    if (_listCtrl == null || !_listCtrl!.hasClients) {
      await Future.delayed(const Duration(milliseconds: 60));
    }
    if (_listCtrl == null || !_listCtrl!.hasClients) return;

    // If current model is pinned and favorites section is visible, jump there first
    final currentKey = '${pk}::${mid}';
    final bool showFavorites = widget.limitProviderKey == null && (_search.text.isEmpty);
    final bool isPinned = settings.pinnedModels.contains(currentKey);
    double? target;
    if (showFavorites && isPinned && _providerOffsets.containsKey('__fav__')) {
      // Compute index of current model within favorites as displayed
      final favKeysDisplay = <String>[];
      for (final k in settings.pinnedModels) {
        final parts = k.split('::');
        if (parts.length < 2) continue;
        final p = parts[0];
        if (_groups[p] == null) continue;
        favKeysDisplay.add(k);
      }
      final favIndex = favKeysDisplay.indexOf(currentKey);
      if (favIndex >= 0) {
        final baseFav = _providerOffsets['__fav__'] ?? 0.0;
        target = baseFav + _sectionHeaderHeight + favIndex * _modelTileHeight;
      }
    }

    // Fallback to provider section if not pinned or favorites not available
    if (target == null) {
      final group = _groups[pk];
      if (group == null) return;
      final index = group.items.indexWhere((e) => e.id == mid);
      if (index < 0) return;
      final base = _providerOffsets[pk] ?? 0.0;
      target = base + _sectionHeaderHeight + index * _modelTileHeight;
    }

    // Use precomputed section offsets from latest build
    final maxOff = _listCtrl!.position.maxScrollExtent;
    final to = target.clamp(0.0, maxOff);

    try {
      await _listCtrl!.animateTo(
        to,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  // Match model name/id only (avoid provider key causing false positives)
  bool _matchesSearch(String query, _ModelItem item, String providerName) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return item.id.toLowerCase().contains(q) || item.info.displayName.toLowerCase().contains(q);
  }

  // Check if a provider should be shown based on search query (match display name only)
  bool _providerMatchesSearch(String query, String providerName) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    final lowerProviderName = providerName.toLowerCase();
    return lowerProviderName.contains(lowerQuery);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          controller: _sheetCtrl,
          expand: false,
          initialChildSize: _initialSize,
          maxChildSize: _maxSize,
          minChildSize: 0.4,
          builder: (c, controller) {
            _listCtrl = controller;
            
            return Column(
              children: [
                // Fixed header section with rounded corners
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      // Header drag indicator
                      Column(children: [
                        const SizedBox(height: 8),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(999))),
                        const SizedBox(height: 8),
                      ]),
                      // Fixed search field
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: _search,
                          enabled: !_isLoading,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.modelSelectSheetSearchHint,
                            prefixIcon: Icon(Lucide.Search, size: 18, color: cs.onSurface.withOpacity(_isLoading ? 0.3 : 0.6)),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F3F5),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
                            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withOpacity(0.4))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: Container(
                    color: cs.surface, // Ensure background color continuity
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(context, controller),
                  ),
                ),
                // Fixed bottom tabs
                Container(
                  color: cs.surface, // Ensure background color continuity
                  child: _buildBottomTabs(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController controller) {
    final l10n = AppLocalizations.of(context)!;
    final query = _search.text.trim();

    // Build a flattened list of entries with fixed heights, and compute offsets
    final List<_Entry> entries = [];
    _providerOffsets.clear();
    double cumulative = 0.0;

    // Favorites section (reactive; only when not limited and not searching)
    if (widget.limitProviderKey == null && query.isEmpty) {
      final pinned = context.watch<SettingsProvider>().pinnedModels;
      if (pinned.isNotEmpty) {
        final favs = <_ModelItem>[];
        for (final k in pinned) {
          final parts = k.split('::');
          if (parts.length < 2) continue;
          final pk = parts[0];
          final mid = parts.sublist(1).join('::');
          final g = _groups[pk];
          if (g == null) continue;
          final found = g.items.firstWhere(
            (e) => e.id == mid,
            orElse: () => _ModelItem(
              providerKey: pk,
              providerName: g.name,
              id: mid,
              info: ModelRegistry.infer(ModelInfo(id: mid, displayName: mid)),
              pinned: true,
              selected: false,
            ),
          );
          if (_matchesSearch(query, found, found.providerName)) {
            favs.add(found.copyWith(pinned: true));
          }
        }
        if (favs.isNotEmpty) {
          _headers['__fav__'] ??= GlobalKey();
          _providerOffsets['__fav__'] = cumulative;
          final favKey = _headers['__fav__']!;
          entries.add(_Entry(
            height: _sectionHeaderHeight,
            builder: () => _sectionHeader(context, l10n.modelSelectSheetFavoritesSection, favKey),
          ));
          cumulative += _sectionHeaderHeight;
          for (final m in favs) {
            entries.add(_Entry(
              height: _modelTileHeight,
              builder: () => _modelTile(context, m, showProviderLabel: true),
            ));
            cumulative += _modelTileHeight;
          }
        }
      }
    }

    // Provider sections with enhanced search
    for (final pk in _orderedKeys) {
      final g = _groups[pk]!;
      List<_ModelItem> items;
      if (query.isEmpty) {
        items = g.items;
      } else {
        final providerMatches = _providerMatchesSearch(query, g.name);
        items = providerMatches
            ? g.items
            : g.items.where((e) => _matchesSearch(query, e, g.name)).toList();
      }
      if (items.isEmpty) continue;

      _headers[pk] ??= GlobalKey();
      _providerOffsets[pk] = cumulative;
      final headerKey = _headers[pk]!;
      entries.add(_Entry(
        height: _sectionHeaderHeight,
        builder: () => _sectionHeader(context, g.name, headerKey),
      ));
      cumulative += _sectionHeaderHeight;

      for (final m in items) {
        entries.add(_Entry(
          height: _modelTileHeight,
          builder: () => _modelTile(context, m),
        ));
        cumulative += _modelTileHeight;
      }
    }

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Precompute prefix heights for O(1) range height queries
    final int n = entries.length;
    final List<double> prefix = List<double>.filled(n + 1, 0.0);
    for (int i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + entries[i].height;
    }

    int lowerBound(List<double> a, double x) {
      int l = 0, r = a.length; // [l, r)
      while (l < r) {
        final m = (l + r) >> 1;
        if (a[m] < x) {
          l = m + 1;
        } else {
          r = m;
        }
      }
      return l;
    }

    const int bufferItems = 8; // small render buffer around viewport 额外渲染的缓冲条目数量

    return LayoutBuilder(
      builder: (context, cons) {
        final viewport = cons.maxHeight;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final has = controller.hasClients;
            final double offset = has ? controller.offset.clamp(0.0, (prefix.last - viewport).clamp(0.0, double.infinity)) as double : 0.0;

            // Find visible index range using prefix sums + binary search
            // startIndex: first entry whose end > offset
            int startIndex = (lowerBound(prefix, offset) - 1).clamp(0, n - 1);
            // endIndex: last entry whose start < offset + viewport
            int endIndex = (lowerBound(prefix, offset + viewport) - 1).clamp(0, n - 1);

            // Expand by buffer
            startIndex = (startIndex - bufferItems).clamp(0, n - 1);
            endIndex = (endIndex + bufferItems).clamp(0, n - 1);

            final double topGap = prefix[startIndex];
            final double bottomGap = prefix.last - prefix[endIndex + 1];

            final visibleChildren = <Widget>[
              for (int i = startIndex; i <= endIndex; i++) entries[i].builder(),
            ];

            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  SizedBox(height: topGap),
                  ...visibleChildren,
                  SizedBox(height: bottomGap),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomTabs(BuildContext context) {
    // Bottom provider tabs (ordered per ProvidersPage order)
    final List<Widget> providerTabs = <Widget>[];
    if (widget.limitProviderKey == null && !_isLoading) {
      for (final k in _orderedKeys) {
        final g = _groups[k];
        if (g != null) {
          providerTabs.add(_providerTab(context, k, g.name));
        }
      }
    }

    if (providerTabs.isEmpty) return const SizedBox.shrink();

    return Padding(
      // SafeArea already applies bottom inset; avoid doubling it here.
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: providerTabs),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, Key key) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: key,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.6))),
    );
  }

  Widget _modelTile(BuildContext context, _ModelItem m, {bool showProviderLabel = false}) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = m.selected ? (isDark ? cs.primary.withOpacity(0.12) : cs.primary.withOpacity(0.08)) : cs.surface;
    final effective = m.info; // precomputed effective info
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: RepaintBoundary(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(ModelSelection(m.providerKey, m.id)),
            onLongPress: () async {
              // Edit model overrides in-place; refresh list after closing
              await showModelDetailSheet(context, providerKey: m.providerKey, modelId: m.id);
              if (mounted) {
                // Recompute to reflect overrides changes
                _isLoading = true;
                setState(() {});
                await _loadModelsAsync();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _BrandAvatar(name: m.id, assetOverride: m.asset, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!showProviderLabel)
                          Text(
                            m.info.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          )
                        else
                          Text.rich(
                            TextSpan(
                              text: m.info.displayName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text: ' | ${m.providerName}',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        _modelTagWrap(context, effective),
                      ],
                    ),
                  ),
                  Builder(builder: (context) {
                    final pinnedNow = context.select<SettingsProvider, bool>((s) => s.isModelPinned(m.providerKey, m.id));
                    final icon = pinnedNow ? Icons.favorite : Icons.favorite_border;
                    return IconButton(
                      onPressed: () => settings.togglePinModel(m.providerKey, m.id),
                      icon: Icon(icon, size: 20, color: cs.primary),
                      tooltip: l10n.modelSelectSheetFavoriteTooltip,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _providerTab(BuildContext context, String key, String name) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: () async { await _jumpToProvider(key); },
        onLongPress: () async {
          // Open provider detail page for quick edits
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderDetailPage(keyName: key, displayName: name),
            ),
          );
          if (mounted) setState(() {});
        },
        icon: _BrandAvatar(name: name, size: 16),
        label: Text(name, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
          backgroundColor: cs.surface,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
    );
  }

  Future<void> _jumpToProvider(String pk) async {
    // Expand sheet first if needed
    if (_sheetCtrl.size < _maxSize) {
      await _sheetCtrl.animateTo(
        _maxSize,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      // Wait a bit for the animation to complete
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Clear search if needed to ensure provider is visible
    if (_search.text.isNotEmpty) {
      setState(() => _search.clear());
      // Wait for the widget tree to rebuild and all widgets to be rendered
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Try to use GlobalKey to scroll to the exact position
    final targetKey = _headers[pk];
    if (targetKey != null) {
      final context = targetKey.currentContext;
      if (context != null) {
        // Use Scrollable.ensureVisible for accurate scrolling
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.0, // Align to top of viewport
        );
        return;
      }
    }
    
    // Fallback: use pre-calculated offset if GlobalKey doesn't work
    final targetOffset = _providerOffsets[pk];
    if (targetOffset != null && _listCtrl?.hasClients == true) {
      // Ensure the offset is within valid bounds
      final scrollTo = targetOffset.clamp(0.0, _listCtrl!.position.maxScrollExtent);
      
      await _listCtrl!.animateTo(
        scrollTo,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _displayName(BuildContext context, _ModelItem m) => m.info.displayName;
  ModelInfo _effectiveInfo(BuildContext context, _ModelItem m) => m.info;
}

class _ProviderGroup {
  final String name;
  final List<_ModelItem> items;
  _ProviderGroup({required this.name, required this.items});
}

class _ModelItem {
  final String providerKey;
  final String providerName;
  final String id;
  final ModelInfo info;
  final bool pinned;
  final bool selected;
  final String? asset; // pre-resolved avatar asset for performance
  _ModelItem({required this.providerKey, required this.providerName, required this.id, required this.info, this.pinned = false, this.selected = false, this.asset});
  _ModelItem copyWith({bool? pinned, bool? selected}) => _ModelItem(providerKey: providerKey, providerName: providerName, id: id, info: info, pinned: pinned ?? this.pinned, selected: selected ?? this.selected, asset: asset);
}

// Virtualization entry: fixed height + lazy builder
class _Entry {
  final double height;
  final Widget Function() builder;
  const _Entry({required this.height, required this.builder});
}

// Reuse badges and avatars similar to provider detail
class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar({required this.name, this.size = 20, this.assetOverride});
  final String name;
  final double size;
  final String? assetOverride;

  String? _assetForName(String n) {
    final lower = n.toLowerCase();
    final mapping = <RegExp, String>{
      RegExp(r'openai|gpt|o\d'): 'openai.svg',
      RegExp(r'gemini'): 'gemini-color.svg',
      RegExp(r'google'): 'google-color.svg',
      RegExp(r'claude'): 'claude-color.svg',
      RegExp(r'anthropic'): 'anthropic.svg',
      RegExp(r'deepseek'): 'deepseek-color.svg',
      RegExp(r'grok'): 'grok.svg',
      RegExp(r'qwen|qwq|qvq|aliyun|dashscope'): 'qwen-color.svg',
      RegExp(r'doubao|ark|volc'): 'doubao-color.svg',
      RegExp(r'openrouter'): 'openrouter.svg',
      RegExp(r'zhipu|智谱|glm'): 'zhipu-color.svg',
      RegExp(r'mistral'): 'mistral-color.svg',
      RegExp(r'(?<!o)llama|meta'): 'meta-color.svg',
      RegExp(r'hunyuan|tencent'): 'hunyuan-color.svg',
      RegExp(r'gemma'): 'gemma-color.svg',
      RegExp(r'perplexity'): 'perplexity-color.svg',
      RegExp(r'aliyun|阿里云|百炼'): 'alibabacloud-color.svg',
      RegExp(r'bytedance|火山'): 'bytedance-color.svg',
      RegExp(r'silicon|硅基'): 'siliconflow-color.svg',
      RegExp(r'aihubmix'): 'aihubmix-color.svg',
      RegExp(r'ollama'): 'ollama.svg',
      RegExp(r'github'): 'github.svg',
      RegExp(r'cloudflare'): 'cloudflare-color.svg',
      RegExp(r'minimax'): 'minimax-color.svg',
      RegExp(r'xai|grok'): 'xai.svg',
      RegExp(r'juhenext'): 'juhenext.png',
      RegExp(r'kimi'): 'kimi-color.svg',
      RegExp(r'302'): '302ai-color.svg',
      RegExp(r'step|阶跃'): 'stepfun-color.svg',
      RegExp(r'intern|书生'): 'internlm-color.svg',
      RegExp(r'cohere|command-.+'): 'cohere-color.svg',
      RegExp(r'kelivo'): 'kelivo.png',
    };
    for (final e in mapping.entries) {
      if (e.key.hasMatch(lower)) return 'assets/icons/${e.value}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = assetOverride ?? _assetForName(name);
    Widget inner;
    if (asset != null) {
      if (asset.endsWith('.svg')) {
        final isColorful = asset.contains('color');
        final dark = Theme.of(context).brightness == Brightness.dark;
        final ColorFilter? tint = (dark && !isColorful)
            ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
            : null;
        inner = SvgPicture.asset(
          asset,
          width: size * 0.62,
          height: size * 0.62,
          colorFilter: tint,
        );
      } else {
        inner = Image.asset(asset, width: size * 0.62, height: size * 0.62, fit: BoxFit.contain);
      }
    } else {
      inner = Text(name.isNotEmpty ? name.characters.first.toUpperCase() : '?', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: size * 0.42));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : cs.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }
}

Widget _modelTagWrap(BuildContext context, ModelInfo m) {
  final cs = Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  List<Widget> chips = [];
  // type tag
  chips.add(Container(
    decoration: BoxDecoration(
      color: isDark ? cs.primary.withOpacity(0.25) : cs.primary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: cs.primary.withOpacity(0.2), width: 0.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: Text(m.type == ModelType.chat ? l10n.modelSelectSheetChatType : l10n.modelSelectSheetEmbeddingType, style: TextStyle(fontSize: 11, color: isDark ? cs.primary : cs.primary.withOpacity(0.9), fontWeight: FontWeight.w500)),
  ));
  // modality tag capsule with icons (keep consistent with provider detail page)
  chips.add(Container(
    decoration: BoxDecoration(
      color: isDark ? cs.tertiary.withOpacity(0.25) : cs.tertiary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: cs.tertiary.withOpacity(0.2), width: 0.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      for (final mod in m.input)
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(mod == Modality.text ? Lucide.Type : Lucide.Image, size: 12, color: isDark ? cs.tertiary : cs.tertiary.withOpacity(0.9)),
        ),
      Icon(Lucide.ChevronRight, size: 12, color: isDark ? cs.tertiary : cs.tertiary.withOpacity(0.9)),
      for (final mod in m.output)
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(mod == Modality.text ? Lucide.Type : Lucide.Image, size: 12, color: isDark ? cs.tertiary : cs.tertiary.withOpacity(0.9)),
        ),
    ]),
  ));
  // abilities capsules
  for (final ab in m.abilities) {
    if (ab == ModelAbility.tool) {
      chips.add(Container(
        decoration: BoxDecoration(
          color: isDark ? cs.primary.withOpacity(0.25) : cs.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withOpacity(0.2), width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Icon(Lucide.Hammer, size: 12, color: isDark ? cs.primary : cs.primary.withOpacity(0.9)),
      ));
    } else if (ab == ModelAbility.reasoning) {
      chips.add(Container(
        decoration: BoxDecoration(
          color: isDark ? cs.secondary.withOpacity(0.3) : cs.secondary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.secondary.withOpacity(0.25), width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: SvgPicture.asset('assets/icons/deepthink.svg', width: 12, height: 12, colorFilter: ColorFilter.mode(isDark ? cs.secondary : cs.secondary.withOpacity(0.9), BlendMode.srcIn)),
      ));
    }
  }
  return Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: chips);
}
