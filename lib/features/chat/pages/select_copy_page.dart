import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../core/models/chat_message.dart';

class SelectCopyPage extends StatelessWidget {
  const SelectCopyPage({super.key, required this.message});
  final ChatMessage message;

  void _copyAll(BuildContext context) async {
    // Ensure there is a text input connection on iOS before showing system copy UI
    // Here we bypass system menu by writing directly to clipboard and showing a snackbar
    await Clipboard.setData(ClipboardData(text: message.content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制全部')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(zh ? '选择复制' : 'Select & Copy'),
        actions: [
          TextButton.icon(
            onPressed: () => _copyAll(context),
            icon: Icon(Lucide.Copy, size: 18, color: cs.primary),
            label: Text(
              zh ? '复制全部' : 'Copy All',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: SelectionArea(
                child: Text(
                  message.content,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
