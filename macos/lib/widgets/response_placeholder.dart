import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A clean placeholder box where the AI's text/voice response will be
/// rendered once the backend is connected.
class ResponsePlaceholder extends StatelessWidget {
  const ResponsePlaceholder({super.key, this.text = 'AI Response will appear here...'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
