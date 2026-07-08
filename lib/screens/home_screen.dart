import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/chat_history_service.dart';
import '../models/language_option.dart'; 
import '../widgets/recent_chat_tile.dart';
import '../widgets/recent_chats_empty_state.dart';
import 'advisory_chat_screen.dart';
import 'language_select_screen.dart';
import 'sign_in_screen.dart';

/// Home screen: a real greeting, "New chat", and a live Recent list of
/// this account's saved conversations.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greetingName(User user) {
    if ((user.displayName ?? '').trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    if ((user.email ?? '').isNotEmpty) {
      return user.email!.split('@').first;
    }
    if ((user.phoneNumber ?? '').isNotEmpty) {
      return user.phoneNumber!;
    }
    return 'Farmer';
  }

  Future<void> _openConversation(
    BuildContext context, {
    required String conversationId,
    required String uid,
  }) async {
    final messages =
        await ChatHistoryService.instance.loadMessages(uid, conversationId);
    if (!context.mounted) return;

    // Saved conversations don't record which language they were in
    // beyond a code — default back to English if that's ever missing,
    // since the language selector already guarantees one exists for
    // new chats going forward.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvisoryChatScreen(
          language: LanguageOption.all.first,
          conversationId: conversationId,
          initialMessages: messages,
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? '';

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
                  Expanded(
                    child: Text(
                      user == null
                          ? 'Welcome back'
                          : 'Welcome back, ${_greetingName(user)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Sign out',
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
              Expanded(
                child: uid.isEmpty
                    ? const RecentChatsEmptyState()
                    : StreamBuilder<List<ConversationSummary>>(
                        stream: ChatHistoryService.instance
                            .watchConversations(uid),
                        builder: (context, snapshot) {
                          final conversations = snapshot.data ?? [];
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              conversations.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          if (conversations.isEmpty) {
                            return const RecentChatsEmptyState();
                          }
                          return ListView.separated(
                            itemCount: conversations.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              return RecentChatTile(
                                title: conversation.title,
                                updatedAt: conversation.updatedAt,
                                onTap: () => _openConversation(
                                  context,
                                  conversationId: conversation.id,
                                  uid: uid,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
