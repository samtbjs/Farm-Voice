import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../utils/relative_time.dart';

/// One row in the Home screen's "Recent" list — mirrors the visual
/// language of [RecentChatsEmptyState] (same surface/border treatment)
/// so a populated list and the empty state look like the same family.
class RecentChatTile extends StatelessWidget {
  const RecentChatTile({
    super.key,
    required this.title,
    required this.updatedAt,
    required this.onTap,
  });

  final String title;
  final DateTime? updatedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.isEmpty ? 'Conversation' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeTime(updatedAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}