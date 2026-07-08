import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/language_option.dart';
import '../widgets/language_option_row.dart';
import 'advisory_chat_screen.dart';

/// Shown after tapping "New chat" on the Home screen. The farmer
/// picks one language before the conversation starts — once chosen,
/// it's locked in for that chat and shown (not editable) on the
/// Advisory chat screen's app bar.
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  LanguageOption? _selected;

  void _continue() {
    if (_selected == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvisoryChatScreen(language: _selected!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _selected != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your language')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: LanguageOption.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final language = LanguageOption.all[index];
                    return LanguageOptionRow(
                      language: language,
                      isSelected: _selected == language,
                      onTap: () => setState(() => _selected = language),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: canContinue ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canContinue ? AppColors.green : AppColors.border,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
