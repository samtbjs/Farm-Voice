import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A rounded text field for typing a question instead of speaking it.
///
/// Styled to match [LanguageDropdown] (same border, radius, surface
/// fill) so it reads as part of the same input group rather than a
/// bolted-on extra. The trailing send button is only enabled once
/// there's text to submit.
class TextQueryField extends StatelessWidget {
  const TextQueryField({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  void _handleSubmit() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _handleSubmit(),
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: 'Type your question here…',
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          suffixIcon: IconButton(
            onPressed: _handleSubmit,
            icon: const Icon(Icons.send_rounded, color: AppColors.green),
          ),
        ),
      ),
    );
  }
}
