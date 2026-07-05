import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A quiet horizontal divider with a centered label, used to separate
/// the voice and text input options without competing with either.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or type your question'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
