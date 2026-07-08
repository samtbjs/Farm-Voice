import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/theme/app_colors.dart';
import '../models/language_option.dart';
import '../services/chat_history_service.dart';
import '../services/gemini_service.dart';
import '../utils/web_camera_capture.dart';
import '../widgets/advisory_bubbles.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/processing_overlay.dart';

/// One combined chat: the farmer can speak, type, or attach a crop
/// photo in any combination, in one place — rather than voice and
/// camera being two separate screens/flows.
///
/// [language] is chosen once on [LanguageSelectScreen] before this
/// screen opens and is shown (not editable) in the app bar — this
/// chat doesn't support switching languages mid-conversation; start
/// a new chat instead.
///
/// [conversationId] and [initialMessages] are set when reopening a
/// past conversation from Home's "Recent" list; both are left null
/// for a brand-new chat, in which case a new Firestore document is
/// created the first time something is sent.
class AdvisoryChatScreen extends StatefulWidget {
  const AdvisoryChatScreen({
    super.key,
    required this.language,
    this.conversationId,
    this.initialMessages,
  });

  final LanguageOption language;
  final String? conversationId;
  final List<StoredMessage>? initialMessages;

  @override
  State<AdvisoryChatScreen> createState() => _AdvisoryChatScreenState();
}

/// A single message in the thread.
///
/// User entries optionally carry the real photo bytes that were sent
/// alongside the text, so the bubble can show a thumbnail.
class _ChatEntry {
  _ChatEntry.user({required this.text, this.imageBytes}) : isUser = true;

  _ChatEntry.advisory({required this.text}) : isUser = false, imageBytes = null;

  final bool isUser;
  final String text;
  final Uint8List? imageBytes;
}

class _AdvisoryChatScreenState extends State<AdvisoryChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatEntry> _thread = [];

  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  Uint8List? _attachedPhoto;
  bool _isRecording = false;
  bool _speechAvailable = false;
  bool _isProcessing = false;
  String _processingMessage = '';

  /// Set once the first message of a brand-new chat is saved, or
  /// immediately from [widget.conversationId] when reopening one.
  String? _activeConversationId;

  @override
  void initState() {
    super.initState();
    _activeConversationId = widget.conversationId;

    final initial = widget.initialMessages;
    if (initial != null && initial.isNotEmpty) {
      for (final stored in initial) {
        if (stored.isUser) {
          _thread.add(_ChatEntry.user(text: stored.text));
        } else {
          _thread.add(_ChatEntry.advisory(text: stored.text));
        }
      }
    }

    _initSpeech();
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        // The plugin flips to "notListening"/"done" on its own once
        // the farmer stops talking — keep our button in sync.
        if (status == 'notListening' || status == 'done') {
          if (mounted && _isRecording) {
            setState(() => _isRecording = false);
          }
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${error.errorMsg}')),
        );
      },
    );

    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  /// Shows a small picker so the farmer can choose between taking a
  /// new photo or picking an existing one from the gallery, then
  /// hands off to [_pickImage] with the chosen source.
  Future<void> _attachPhoto() async {
    if (_isProcessing) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.amber,
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.amber,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Uint8List? bytes;

      // On web, image_picker's "camera" source just opens the same
      // file-picker as "gallery" on desktop browsers (the `capture`
      // hint it relies on is mostly a mobile-browser-only behavior).
      // Route it through a real getUserMedia camera preview instead
      // so "Take Photo" actually opens the webcam on web too.
      if (kIsWeb && source == ImageSource.camera) {
        bytes = await captureFromWebCamera(context);
      } else {
        final XFile? photo = await _picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
        );

        // Farmer backed out of the camera/gallery without picking a photo.
        if (photo == null) return;

        bytes = await photo.readAsBytes();
      }

      // Farmer canceled the web camera dialog without capturing.
      if (bytes == null) return;

      if (!mounted) return;
      setState(() => _attachedPhoto = bytes);
    } catch (e) {
      if (!mounted) return;
      final String sourceLabel =
          source == ImageSource.camera ? 'camera' : 'gallery';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the $sourceLabel. Please check permissions '
            'and try again.',
          ),
        ),
      );
    }
  }

  void _removePhoto() {
    setState(() => _attachedPhoto = null);
  }

  Future<void> _toggleMic() async {
    if (_isProcessing) return;

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
        ),
      );
      return;
    }

    if (_isRecording) {
      await _speech.stop();
      if (mounted) setState(() => _isRecording = false);
      return;
    }

    setState(() => _isRecording = true);

    await _speech.listen(
      localeId: widget.language.localeId,
      onResult: (result) {
        if (result.finalResult) {
          final recognizedText = result.recognizedWords.trim();
          setState(() => _isRecording = false);
          if (recognizedText.isNotEmpty) {
            _handleSend(recognizedText);
          }
        }
      },
    );
  }

  /// Handles all three entry points — typed send, transcribed speech,
  /// and photo (with or without accompanying text) — since by the
  /// time this is called they've all converged to "some text, maybe a
  /// photo".
  Future<void> _handleSend(String text) async {
    if (_isProcessing) return;

    final Uint8List? photoBytes = _attachedPhoto;
    final bool hasPhoto = photoBytes != null;

    setState(() {
      _thread.add(
        _ChatEntry.user(
          text: text.isEmpty ? 'Sent a photo' : text,
          imageBytes: photoBytes,
        ),
      );
      _attachedPhoto = null;
      _isProcessing = true;
      _processingMessage = hasPhoto
          ? 'Analyzing your crop photo…'
          : 'Getting your advisory…';
    });

    // Everything already in the thread *before* this new message is
    // the conversation's memory — send it along so Gemini remembers
    // earlier turns (e.g. the farmer's name, or a crop mentioned a
    // few messages back) instead of answering as if this were the
    // very first message every single time.
    final List<ChatTurn> history = _thread
        .take(_thread.length - 1)
        .map((e) => ChatTurn(isUser: e.isUser, text: e.text))
        .toList();

    final String response = hasPhoto
        ? await _geminiService.analyzeCropImage(
            photoBytes,
            extraContext: text.isEmpty ? null : text,
            language: widget.language,
          )
        : await _geminiService.getVoiceAdvisory(text, widget.language, history);

    if (!mounted) return;

    setState(() {
      _thread.add(_ChatEntry.advisory(text: response));
      _isProcessing = false;
    });

    _persistConversation();
  }

  /// Saves the whole thread under the signed-in account. Creates the
  /// Firestore conversation document on the very first save of a new
  /// chat, then just overwrites it on every later exchange.
  Future<void> _persistConversation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      _activeConversationId ??= await ChatHistoryService.instance
          .createConversation(uid: uid, language: widget.language);

      final messages = _thread
          .map((e) => StoredMessage(isUser: e.isUser, text: e.text))
          .toList();

      await ChatHistoryService.instance.saveMessages(
        uid: uid,
        conversationId: _activeConversationId!,
        messages: messages,
      );
    } catch (_) {
      // Saving history should never crash the chat itself — the
      // farmer can keep chatting even if a save attempt fails (e.g.
      // no network connection right now).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Voice'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.language.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: _thread.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mic_none_rounded,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Speak, type, or add a photo of your crop.\nDo one, or all together.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _thread.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final entry = _thread[index];

                              if (entry.isUser) {
                                return QueryBubble(
                                  text: entry.text,
                                  imageBytes: entry.imageBytes,
                                );
                              }

                              return AdvisoryBubble(text: entry.text);
                            },
                          ),
                  ),
                  if (_isRecording) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Listening… tap the mic to stop',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  ChatInputBar(
                    controller: _controller,
                    photoBytes: _attachedPhoto,
                    isRecording: _isRecording,
                    enabled: !_isProcessing,
                    onAttachPhoto: _attachPhoto,
                    onRemovePhoto: _removePhoto,
                    onMicTap: _toggleMic,
                    onSend: _handleSend,
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              Positioned.fill(
                child: ProcessingOverlay(message: _processingMessage),
              ),
          ],
        ),
      ),
    );
  }
}
