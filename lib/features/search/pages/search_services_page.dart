import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/search/search_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/snackbar.dart';
import '../../../utils/brand_assets.dart';

class SearchServicesPage extends StatefulWidget {
  const SearchServicesPage({super.key});

  @override
  State<SearchServicesPage> createState() => _SearchServicesPageState();
}

class _SearchServicesPageState extends State<SearchServicesPage> {
  bool _isEditing = false;
  List<SearchServiceOptions> _services = [];
  int _selectedIndex = 0;
  final Map<String, bool> _testing = <String, bool>{}; // serviceId -> testing
  // Use SettingsProvider for connection results; keep only local testing spinner state

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _services = List.from(settings.searchServices);
    _selectedIndex = settings.searchServiceSelected;
    // Do not auto test here; rely on app-start tests. Users can test manually.
  }

  void _addService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddServiceBottomSheet(
        onAdd: (service) {
          setState(() {
            _services.add(service);
          });
          _saveChanges();
        },
      ),
    );
  }

  void _editService(int index) {
    final service = _services[index];
    showDialog(
      context: context,
      builder: (context) => _EditServiceDialog(
        service: service,
        onSave: (updated) {
          setState(() {
            _services[index] = updated;
          });
          _saveChanges();
        },
      ),
    );
  }

  void _deleteService(int index) {
    if (_services.length <= 1) {
      final l10n = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        message: l10n.searchServicesPageAtLeastOneServiceRequired,
        type: NotificationType.warning,
      );
      return;
    }
    
    setState(() {
      _services.removeAt(index);
      if (_selectedIndex >= _services.length) {
        _selectedIndex = _services.length - 1;
      } else if (_selectedIndex > index) {
        _selectedIndex--;
      }
    });
    _saveChanges();
  }

  void _selectService(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveChanges();
  }

  void _saveChanges() {
    final settings = context.read<SettingsProvider>();
    context.read<SettingsProvider>().updateSettings(
      settings.copyWith(
        searchServices: _services,
        searchServiceSelected: _selectedIndex,
      ),
    );
  }

  Future<void> _testConnection(int index) async {
    if (index < 0 || index >= _services.length) return;
    final s = _services[index];
    final id = s.id;
    setState(() {
      _testing[id] = true;
    });
    try {
      final svc = SearchService.getService(s);
      final settings = context.read<SettingsProvider>();
      // Use a tiny search to validate connectivity
      final common = SearchCommonOptions(
        resultSize: 1,
        timeout: settings.searchCommonOptions.timeout,
      );
      await svc.search(
        query: 'connectivity test',
        commonOptions: common,
        serviceOptions: s,
      );
      settings.setSearchConnection(id, true);
    } catch (_) {
      context.read<SettingsProvider>().setSearchConnection(id, false);
    } finally {
      setState(() {
        _testing[id] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Lucide.ArrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: l10n.searchServicesPageBackTooltip,
        ),
        title: Text(l10n.searchServicesPageTitle),
        actions: [
          IconButton(
            tooltip: _isEditing ? l10n.searchServicesPageDone : l10n.searchServicesPageEdit,
            icon: Icon(_isEditing ? Lucide.Check : Lucide.Edit, color: cs.onSurface),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.searchServicesPageAddProvider,
            icon: Icon(Lucide.Plus, color: cs.onSurface),
            onPressed: _addService,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _sectionHeader(l10n.searchServicesPageSearchProviders, cs),
          const SizedBox(height: 8),
          for (int i = 0; i < _services.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProviderCard(context, i),
            ),
          ],
          const SizedBox(height: 18),
          _sectionHeader(l10n.searchServicesPageGeneralOptions, cs),
          const SizedBox(height: 8),
          _buildCommonOptionsCard(context),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
      );

  Widget _buildCommonOptionsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final commonOptions = settings.searchCommonOptions;
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? Colors.white10 : cs.primary.withOpacity(0.06);
    final border = cs.primary.withOpacity(0.35);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        padding: const EdgeInsets.all(14),
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.searchServicesPageMaxResults, style: const TextStyle(fontWeight: FontWeight.w700)),
            Row(
              children: [
                IconButton(
                  icon: Icon(Lucide.Minus),
                  onPressed: commonOptions.resultSize > 1 ? () {
                    context.read<SettingsProvider>().updateSettings(
                      settings.copyWith(
                        searchCommonOptions: SearchCommonOptions(
                          resultSize: commonOptions.resultSize - 1,
                          timeout: commonOptions.timeout,
                        ),
                      ),
                    );
                  } : null,
                ),
                Text('${commonOptions.resultSize}'),
                IconButton(
                  icon: Icon(Lucide.Plus),
                  onPressed: commonOptions.resultSize < 20 ? () {
                    context.read<SettingsProvider>().updateSettings(
                      settings.copyWith(
                        searchCommonOptions: SearchCommonOptions(
                          resultSize: commonOptions.resultSize + 1,
                          timeout: commonOptions.timeout,
                        ),
                      ),
                    );
                  } : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.searchServicesPageTimeoutSeconds, style: const TextStyle(fontWeight: FontWeight.w700)),
            Row(
              children: [
                IconButton(
                  icon: Icon(Lucide.Minus),
                  onPressed: commonOptions.timeout > 1000 ? () {
                    context.read<SettingsProvider>().updateSettings(
                      settings.copyWith(
                        searchCommonOptions: SearchCommonOptions(
                          resultSize: commonOptions.resultSize,
                          timeout: commonOptions.timeout - 1000,
                        ),
                      ),
                    );
                  } : null,
                ),
                Text('${commonOptions.timeout ~/ 1000}'),
                IconButton(
                  icon: Icon(Lucide.Plus),
                  onPressed: commonOptions.timeout < 30000 ? () {
                    context.read<SettingsProvider>().updateSettings(
                      settings.copyWith(
                        searchCommonOptions: SearchCommonOptions(
                          resultSize: commonOptions.resultSize,
                          timeout: commonOptions.timeout + 1000,
                        ),
                      ),
                    );
                  } : null,
                ),
              ],
            ),
          ],
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(BuildContext context, int index) {
    final service = _services[index];
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = index == _selectedIndex;
    final searchService = SearchService.getService(service);
    final l10n = AppLocalizations.of(context)!;
    final bg = isDark ? Colors.white10 : cs.primary.withOpacity(0.06);
    final border = isSelected ? cs.primary : cs.primary.withOpacity(0.35);
    // Connection status label (replaces previous "已配置/需要Key")
    final testing = _testing[service.id] == true;
    final conn = context.watch<SettingsProvider>().searchConnection[service.id];
    String statusText;
    Color statusBg;
    Color statusFg;
    if (testing) {
      statusText = l10n.searchServicesPageTestingStatus;
      statusBg = cs.primary.withOpacity(0.12);
      statusFg = cs.primary;
    } else if (conn == true) {
      statusText = l10n.searchServicesPageConnectedStatus;
      statusBg = Colors.green.withOpacity(0.12);
      statusFg = Colors.green;
    } else if (conn == false) {
      statusText = l10n.searchServicesPageFailedStatus;
      statusBg = Colors.orange.withOpacity(0.12);
      statusFg = Colors.orange;
    } else {
      statusText = l10n.searchServicesPageNotTestedStatus;
      statusBg = cs.onSurface.withOpacity(0.06);
      statusFg = cs.onSurface.withOpacity(0.7);
    }

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectService(index),
        child: Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: isSelected ? 1.4 : 1)),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandBadge.forService(service, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(searchService.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                        if (_isEditing) ...[
                          // Test connection button (omit for local Bing)
                          if (service is! BingLocalOptions)
                            (testing
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    tooltip: l10n.searchServicesPageTestConnectionTooltip,
                                    icon: Icon(Lucide.Activity, size: 18, color: cs.onSurface.withOpacity(0.9)),
                                    onPressed: () => _testConnection(index),
                                  ))
                          else
                            const SizedBox(width: 24, height: 24),
                          IconButton(icon: Icon(Lucide.Edit, size: 18, color: cs.onSurface.withOpacity(0.9)), onPressed: () => _editService(index)),
                          IconButton(
                            icon: Icon(Lucide.Trash2, size: 18, color: cs.onSurface.withOpacity(0.9)),
                            onPressed: () => _deleteService(index),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    DefaultTextStyle.merge(style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.8)), child: searchService.description(context)),
                    if (service is! BingLocalOptions && statusText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)), child: Text(statusText, style: TextStyle(fontSize: 11, color: statusFg))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(SearchServiceOptions service) {
    if (service is BingLocalOptions) return Lucide.Search;
    if (service is TavilyOptions) return Lucide.Sparkles;
    if (service is ExaOptions) return Lucide.Brain;
    if (service is ZhipuOptions) return Lucide.Languages;
    if (service is SearXNGOptions) return Lucide.Shield;
    if (service is LinkUpOptions) return Lucide.Link2;
    if (service is BraveOptions) return Lucide.Shield;
    if (service is MetasoOptions) return Lucide.Compass;
    return Lucide.Search;
  }

  String? _getServiceStatus(SearchServiceOptions service) {
    final l10n = AppLocalizations.of(context)!;
    if (service is BingLocalOptions) return null;
    if (service is TavilyOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    if (service is ExaOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    if (service is ZhipuOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    if (service is SearXNGOptions) return service.url.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageUrlRequiredStatus;
    if (service is LinkUpOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    if (service is BraveOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    if (service is MetasoOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    if (service is OllamaOptions) return service.apiKey.isNotEmpty ? l10n.searchServicesPageConfiguredStatus : l10n.searchServicesPageApiKeyRequiredStatus;
    return null;
  }

  // Brand badge for known services using assets/icons; falls back to letter if unknown
  // ignore: unused_element
  Widget _brandBadgeForName(String name, {double size = 20}) => _BrandBadge(name: name, size: size);
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.name, this.size = 20});
  final String name;
  final double size;

  static Widget forService(SearchServiceOptions s, {double size = 24}) {
    final n = _nameForService(s);
    return _BrandBadge(name: n, size: size);
  }

  static String _nameForService(SearchServiceOptions s) {
    if (s is BingLocalOptions) return 'Bing';
    if (s is TavilyOptions) return 'Tavily';
    if (s is ExaOptions) return 'Exa';
    if (s is ZhipuOptions) return '智谱';
    if (s is SearXNGOptions) return 'SearXNG';
    if (s is LinkUpOptions) return 'LinkUp';
    if (s is BraveOptions) return 'Brave';
    if (s is MetasoOptions) return 'Metaso';
    if (s is OllamaOptions) return 'Ollama';
    return 'Search';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lower = name.toLowerCase();
    String? asset;
    final mapping = <RegExp, String>{
      RegExp(r'bing'): 'bing.png',
      RegExp(r'zhipu|glm|智谱'): 'zhipu-color.svg',
      RegExp(r'tavily'): 'tavily.png',
      RegExp(r'exa'): 'exa.png',
      RegExp(r'linkup'): 'linkup.png',
      RegExp(r'brave'): 'brave-color.svg',
      RegExp(r'ollama'): 'ollama.svg',
      // SearXNG/Metaso fall back to letter
    };
    for (final e in mapping.entries) {
      if (e.key.hasMatch(lower)) { asset = 'assets/icons/${e.value}'; break; }
    }
    final bg = isDark ? Colors.white10 : cs.primary.withOpacity(0.1);
    if (asset != null) {
      if (asset!.endsWith('.svg')) {
        final isColorful = asset!.contains('color');
        final ColorFilter? tint = (isDark && !isColorful) ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: SvgPicture.asset(asset!, width: size * 0.62, height: size * 0.62, colorFilter: tint),
        );
      } else {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Image.asset(asset!, width: size * 0.62, height: size * 0.62, fit: BoxFit.contain),
        );
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name.characters.first.toUpperCase() : '?', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
  }
}

// Add Service Bottom Sheet - iOS Style
class _AddServiceBottomSheet extends StatefulWidget {
  final Function(SearchServiceOptions) onAdd;

  const _AddServiceBottomSheet({required this.onAdd});

  @override
  State<_AddServiceBottomSheet> createState() => _AddServiceBottomSheetState();
}

class _AddServiceBottomSheetState extends State<_AddServiceBottomSheet> {
  String? _selectedType;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: Padding(
                  key: ValueKey<String?>(_selectedType),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    _selectedType == null ? l10n.searchServicesAddDialogTitle : _getServiceName(_selectedType!),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              
              // Service type selection or form with fade animation
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _selectedType == null
                      ? _buildServiceTypeList()
                      : _buildFormView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTypeList() {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final services = [
      {'type': 'bing_local', 'name': l10n.searchServiceNameBingLocal},
      {'type': 'tavily', 'name': l10n.searchServiceNameTavily},
      {'type': 'exa', 'name': l10n.searchServiceNameExa},
      {'type': 'zhipu', 'name': l10n.searchServiceNameZhipu},
      {'type': 'searxng', 'name': l10n.searchServiceNameSearXNG},
      {'type': 'linkup', 'name': l10n.searchServiceNameLinkUp},
      {'type': 'brave', 'name': l10n.searchServiceNameBrave},
      {'type': 'metaso', 'name': l10n.searchServiceNameMetaso},
      {'type': 'ollama', 'name': l10n.searchServiceNameOllama},
    ];
    
    return ListView.builder(
      key: const ValueKey('service_list'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      shrinkWrap: true,
      itemCount: services.length,
      itemBuilder: (context, index) {
          final service = services[index];
          final isLast = index == services.length - 1;
          
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedType = service['type'] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(isDark ? 0.18 : 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _ServiceIcon(
                          type: service['type'] as String,
                          name: service['name'] as String,
                          size: 40,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            service['name'] as String,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(
                          Lucide.ChevronRight,
                          size: 20,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast) const SizedBox(height: 10),
            ],
          );
      },
    );
  }

  String _getServiceName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'bing_local': return l10n.searchServiceNameBingLocal;
      case 'tavily': return l10n.searchServiceNameTavily;
      case 'exa': return l10n.searchServiceNameExa;
      case 'zhipu': return l10n.searchServiceNameZhipu;
      case 'searxng': return l10n.searchServiceNameSearXNG;
      case 'linkup': return l10n.searchServiceNameLinkUp;
      case 'brave': return l10n.searchServiceNameBrave;
      case 'metaso': return l10n.searchServiceNameMetaso;
      case 'ollama': return l10n.searchServiceNameOllama;
      default: return '';
    }
  }

  Widget _buildFormView() {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      key: const ValueKey('form_view'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ..._buildFieldsForType(_selectedType!),
            const SizedBox(height: 20),
            // Add button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final service = _createService();
                    widget.onAdd(service);
                    Navigator.pop(context);
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.searchServicesAddDialogAdd,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForType(String type) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget _buildTextField({
      required String key,
      required String label,
      String? hint,
      bool obscureText = false,
      String? Function(String?)? validator,
    }) {
      _controllers[key] ??= TextEditingController();
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(isDark ? 0.18 : 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextFormField(
          controller: _controllers[key],
          obscureText: obscureText,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      );
    }
    
    switch (type) {
      case 'bing_local':
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(isDark ? 0.18 : 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Lucide.Search, size: 20, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.searchServiceNameBingLocal,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      case 'tavily':
      case 'exa':
      case 'zhipu':
      case 'linkup':
      case 'brave':
      case 'metaso':
      case 'ollama':
        return [
          _buildTextField(
            key: 'apiKey',
            label: 'API Key',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.searchServicesAddDialogApiKeyRequired;
              }
              return null;
            },
          ),
        ];
      case 'searxng':
        return [
          _buildTextField(
            key: 'url',
            label: l10n.searchServicesAddDialogInstanceUrl,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.searchServicesAddDialogUrlRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            key: 'engines',
            label: l10n.searchServicesAddDialogEnginesOptional,
            hint: 'google,duckduckgo',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            key: 'language',
            label: l10n.searchServicesAddDialogLanguageOptional,
            hint: 'en-US',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            key: 'username',
            label: l10n.searchServicesAddDialogUsernameOptional,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            key: 'password',
            label: l10n.searchServicesAddDialogPasswordOptional,
            obscureText: true,
          ),
        ];
      default:
        return [];
    }
  }

  SearchServiceOptions _createService() {
    final uuid = const Uuid();
    final id = uuid.v4().substring(0, 8);
    
    switch (_selectedType) {
      case 'bing_local':
        return BingLocalOptions(id: id);
      case 'tavily':
        return TavilyOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      case 'exa':
        return ExaOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      case 'zhipu':
        return ZhipuOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      case 'searxng':
        return SearXNGOptions(
          id: id,
          url: _controllers['url']!.text,
          engines: _controllers['engines']!.text,
          language: _controllers['language']!.text,
          username: _controllers['username']!.text,
          password: _controllers['password']!.text,
        );
      case 'linkup':
        return LinkUpOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      case 'brave':
        return BraveOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      case 'metaso':
        return MetasoOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      case 'ollama':
        return OllamaOptions(
          id: id,
          apiKey: _controllers['apiKey']!.text,
        );
      default:
        return BingLocalOptions(id: id);
    }
  }
}

// Edit Service Dialog
class _EditServiceDialog extends StatefulWidget {
  final SearchServiceOptions service;
  final Function(SearchServiceOptions) onSave;

  const _EditServiceDialog({
    required this.service,
    required this.onSave,
  });

  @override
  State<_EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<_EditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final service = widget.service;
    if (service is TavilyOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    } else if (service is ExaOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    } else if (service is ZhipuOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    } else if (service is SearXNGOptions) {
      _controllers['url'] = TextEditingController(text: service.url);
      _controllers['engines'] = TextEditingController(text: service.engines);
      _controllers['language'] = TextEditingController(text: service.language);
      _controllers['username'] = TextEditingController(text: service.username);
      _controllers['password'] = TextEditingController(text: service.password);
    } else if (service is LinkUpOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    } else if (service is BraveOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    } else if (service is MetasoOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    } else if (service is OllamaOptions) {
      _controllers['apiKey'] = TextEditingController(text: service.apiKey);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchService = SearchService.getService(widget.service);
    
    return AlertDialog(
      title: Text('${l10n.searchServicesEditDialogEdit} ${searchService.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildFields(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.searchServicesEditDialogCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updated = _updateService();
              widget.onSave(updated);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.searchServicesEditDialogSave),
        ),
      ],
    );
  }

  List<Widget> _buildFields() {
    final l10n = AppLocalizations.of(context)!;
    final service = widget.service;
    
    if (service is BingLocalOptions) {
      return [Text(l10n.searchServicesEditDialogBingLocalNoConfig)];
    } else if (service is TavilyOptions || 
               service is ExaOptions || 
               service is ZhipuOptions ||
               service is LinkUpOptions ||
               service is BraveOptions ||
               service is MetasoOptions ||
               service is OllamaOptions) {
      return [
        TextFormField(
          controller: _controllers['apiKey'],
          decoration: const InputDecoration(
            labelText: 'API Key',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.searchServicesEditDialogApiKeyRequired;
            }
            return null;
          },
        ),
      ];
    } else if (service is SearXNGOptions) {
      return [
        TextFormField(
          controller: _controllers['url'],
          decoration: InputDecoration(
            labelText: l10n.searchServicesEditDialogInstanceUrl,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.searchServicesEditDialogUrlRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controllers['engines'],
          decoration: InputDecoration(
            labelText: l10n.searchServicesEditDialogEnginesOptional,
            hintText: 'google,duckduckgo',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controllers['language'],
          decoration: InputDecoration(
            labelText: l10n.searchServicesEditDialogLanguageOptional,
            hintText: 'en-US',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controllers['username'],
          decoration: InputDecoration(
            labelText: l10n.searchServicesEditDialogUsernameOptional,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controllers['password'],
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.searchServicesEditDialogPasswordOptional,
            border: const OutlineInputBorder(),
          ),
        ),
      ];
    }
    
    return [];
  }

  SearchServiceOptions _updateService() {
    final service = widget.service;
    
    if (service is TavilyOptions) {
      return TavilyOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    } else if (service is ExaOptions) {
      return ExaOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    } else if (service is ZhipuOptions) {
      return ZhipuOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    } else if (service is SearXNGOptions) {
      return SearXNGOptions(
        id: service.id,
        url: _controllers['url']!.text,
        engines: _controllers['engines']!.text,
        language: _controllers['language']!.text,
        username: _controllers['username']!.text,
        password: _controllers['password']!.text,
      );
    } else if (service is LinkUpOptions) {
      return LinkUpOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    } else if (service is BraveOptions) {
      return BraveOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    } else if (service is MetasoOptions) {
      return MetasoOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    } else if (service is OllamaOptions) {
      return OllamaOptions(
        id: service.id,
        apiKey: _controllers['apiKey']!.text,
      );
    }
    
    return service;
  }
}

// Service Icon Widget - Uses BrandAssets
class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({
    required this.type,
    required this.name,
    this.size = 40,
  });

  final String type;  // Service type like 'bing_local', 'tavily', etc.
  final String name;  // Display name for fallback
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use type for matching, not the localized name
    final matchName = _getMatchName(type);
    final asset = BrandAssets.assetForName(matchName);
    final bg = isDark ? Colors.white10 : cs.primary.withOpacity(0.1);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: asset != null
          ? _buildAssetIcon(asset, size, isDark)
          : _buildLetterIcon(name, size, cs),
    );
  }

  Widget _buildAssetIcon(String asset, double size, bool isDark) {
    final iconSize = size * 0.62;
    if (asset.endsWith('.svg')) {
      final isColorful = asset.contains('color');
      final ColorFilter? tint = (isDark && !isColorful) 
          ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) 
          : null;
      return SvgPicture.asset(
        asset,
        width: iconSize,
        height: iconSize,
        colorFilter: tint,
      );
    } else {
      return Image.asset(
        asset,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildLetterIcon(String name, double size, ColorScheme cs) {
    return Text(
      name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
      style: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.w700,
        fontSize: size * 0.42,
      ),
    );
  }

  // Map service type to name for BrandAssets matching
  String _getMatchName(String type) {
    switch (type) {
      case 'bing_local':
        return 'bing';
      case 'tavily':
        return 'tavily';
      case 'exa':
        return 'exa';
      case 'zhipu':
        return 'zhipu';
      case 'searxng':
        return 'searxng';
      case 'linkup':
        return 'linkup';
      case 'brave':
        return 'brave';
      case 'metaso':
        return 'metaso';
      case 'ollama':
        return 'ollama';
      default:
        return type;
    }
  }
}
