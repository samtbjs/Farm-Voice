import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shown under "Recent" on the Home screen when there's no chat
/// history yet. Deliberately has no dummy/sample entries — wire this
/// up to real stored conversations, and swap this out for a list.
class RecentChatsEmptyState extends StatelessWidget {
  const RecentChatsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'Your past conversations will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
