import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/language_option.dart';

/// A single saved message. Photos are intentionally not persisted here
/// (see the top-level explanation) — only the text and sender role
/// survive a reload.
class StoredMessage {
  StoredMessage({
    required this.isUser,
    required this.text,
  });

  final bool isUser;
  final String text;

  Map<String, dynamic> toMap() => {
        'isUser': isUser,
        'text': text,
      };

  factory StoredMessage.fromMap(Map<String, dynamic> map) => StoredMessage(
        isUser: map['isUser'] as bool? ?? false,
        text: map['text'] as String? ?? '',
      );
}

/// Lightweight summary used for the Home screen's "Recent" list — full
/// message bodies are only loaded when a conversation is actually opened.
class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime? updatedAt;
}

class ChatHistoryService {
  ChatHistoryService._internal();
  static final ChatHistoryService instance = ChatHistoryService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _conversations(String uid) =>
      _db.collection('users').doc(uid).collection('conversations');

  /// Live, most-recent-first list of a user's saved conversations.
  Stream<List<ConversationSummary>> watchConversations(String uid) {
    return _conversations(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final Timestamp? ts = data['updatedAt'] as Timestamp?;
              return ConversationSummary(
                id: doc.id,
                title: data['title'] as String? ?? 'Conversation',
                updatedAt: ts?.toDate(),
              );
            }).toList());
  }

  Future<List<StoredMessage>> loadMessages(
    String uid,
    String conversationId,
  ) async {
    final doc = await _conversations(uid).doc(conversationId).get();
    final data = doc.data();
    if (data == null) return [];
    final List<dynamic> raw = data['messages'] as List<dynamic>? ?? [];
    return raw
        .map((m) => StoredMessage.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// Creates a new, empty conversation document and returns its id.
  Future<String> createConversation({
    required String uid,
    required LanguageOption language,
  }) async {
    final ref = await _conversations(uid).add({
      'title': 'New conversation',
      'languageCode': language.code,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'messages': <Map<String, dynamic>>[],
    });
    return ref.id;
  }

  /// Overwrites the message list + title + updatedAt for a
  /// conversation. Called after every exchange so the thread is
  /// always fully saved, not just at the end.
  Future<void> saveMessages({
    required String uid,
    required String conversationId,
    required List<StoredMessage> messages,
  }) async {
    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => StoredMessage(isUser: true, text: 'Conversation'),
    );
    final title = firstUserMessage.text.length > 40
        ? '${firstUserMessage.text.substring(0, 40)}…'
        : firstUserMessage.text;

    await _conversations(uid).doc(conversationId).set({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
      'messages': messages.map((m) => m.toMap()).toList(),
    }, SetOptions(merge: true));
  }
}