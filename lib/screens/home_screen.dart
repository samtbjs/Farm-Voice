import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/recent_chats_empty_state.dart';
import 'language_select_screen.dart';

/// Home screen: a greeting, a single "New chat" action, and a Recent
/// section for resuming past conversations.
///
/// Layout only — [RecentChatsEmptyState] is a placeholder for an
/// empty list; swap it out for a real, scrollable chat history list
/// once conversations are actually being stored.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LanguageSelectScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('New chat'),
              ),
              const SizedBox(height: 28),
              Text(
                'Recent',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const RecentChatsEmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}
