import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/language_option.dart';

/// One selectable row on [LanguageSelectScreen] — native-script label,
/// a radio-style indicator, and a highlighted state when selected.
class LanguageOptionRow extends StatelessWidget {
  const LanguageOptionRow({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final LanguageOption language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.green.withValues(alpha: 0.10) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.green : AppColors.textMuted,
                    width: isSelected ? 6 : 2,
                  ),
                  color: isSelected ? AppColors.green : Colors.transparent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                language.label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
