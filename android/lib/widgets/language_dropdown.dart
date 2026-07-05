import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/language_option.dart';

/// A simple dropdown for choosing the advisory's spoken language.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final LanguageOption? selected;
  final ValueChanged<LanguageOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LanguageOption>(
          value: selected,
          hint: const Text('Choose language'),
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded),
          items: [
            for (final language in LanguageOption.all)
              DropdownMenuItem(
                value: language,
                child: Text(language.label),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
