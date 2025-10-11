import 'package:flutter/foundation.dart';
import '../models/quick_phrase.dart';
import '../services/quick_phrase_store.dart';

class QuickPhraseProvider with ChangeNotifier {
  List<QuickPhrase> _phrases = [];
  bool _initialized = false;

  List<QuickPhrase> get phrases => List.unmodifiable(_phrases);
  
  List<QuickPhrase> get globalPhrases => 
      _phrases.where((p) => p.isGlobal).toList();
  
  List<QuickPhrase> getForAssistant(String assistantId) =>
      _phrases.where((p) => !p.isGlobal && p.assistantId == assistantId).toList();

  Future<void> initialize() async {
    if (_initialized) return;
    await loadAll();
    _initialized = true;
  }

  Future<void> loadAll() async {
    try {
      _phrases = await QuickPhraseStore.getAll();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load quick phrases: $e');
      _phrases = [];
      notifyListeners();
    }
  }

  Future<void> add(QuickPhrase phrase) async {
    await QuickPhraseStore.add(phrase);
    await loadAll();
  }

  Future<void> update(QuickPhrase phrase) async {
    await QuickPhraseStore.update(phrase);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await QuickPhraseStore.delete(id);
    await loadAll();
  }

  Future<void> clear() async {
    await QuickPhraseStore.clear();
    _phrases = [];
    notifyListeners();
  }
}
