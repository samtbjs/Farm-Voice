import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/theme/app_colors.dart';
import '../models/language_option.dart';
import '../services/chat_history_service.dart';
import '../services/gemini_service.dart';
import '../utils/tts_helpers.dart';
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
/// alongside the text, so the bubble can show a thumbnail. Advisory
/// (AI) entries track whether they came from a crop-photo diagnosis
/// (to show the expert-escalation button) and whether that diagnosis
/// has already been flagged.
class _ChatEntry {
  _ChatEntry.user({required this.text, this.imageBytes})
      : isUser = true,
        isCropDiagnosis = false,
        isFlagged = false;

  _ChatEntry.advisory({
    required this.text,
    this.isCropDiagnosis = false,
    this.isFlagged = false,
  })  : isUser = false,
        imageBytes = null;

  final bool isUser;
  final String text;
  final Uint8List? imageBytes;
  final bool isCropDiagnosis;
  bool isFlagged;
}

class _AdvisoryChatScreenState extends State<AdvisoryChatScreen> {
  // TODO: replace with real district lookup post-hackathon (ported
  // as-is from the old CropResultScreen's mock flag confirmation).
  static const String _mockDistrictName = 'Warangal';

  final TextEditingController _controller = TextEditingController();
  final List<_ChatEntry> _thread = [];

  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  Uint8List? _attachedPhoto;
  bool _isRecording = false;
  bool _speechAvailable = false;
  bool _isProcessing = false;
  String _processingMessage = '';
  int? _speakingIndex;

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
          _thread.add(
            _ChatEntry.advisory(
              text: stored.text,
              isCropDiagnosis: stored.isCropDiagnosis,
              isFlagged: stored.isFlagged,
            ),
          );
        }
      }
    }

    _initSpeech();
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    _tts.stop();
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
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      // Farmer backed out of the camera/gallery without picking a photo.
      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();

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

    final String response = hasPhoto
        ? await _geminiService.analyzeCropImage(
            photoBytes,
            extraContext: text.isEmpty ? null : text,
          )
        : await _geminiService.getVoiceAdvisory(text, widget.language);

    if (!mounted) return;

    final int newEntryIndex = _thread.length;
    setState(() {
      _thread.add(
        _ChatEntry.advisory(text: response, isCropDiagnosis: hasPhoto),
      );
      _isProcessing = false;
    });

    _speak(newEntryIndex, response);
    _persistConversation();
  }

  Future<void> _speak(int index, String text) async {
    if (!mounted) return;
    setState(() => _speakingIndex = index);

    try {
      final result = await _tts.setLanguage(ttsLocaleFor(widget.language));
      if (result != 1) {
        await _tts.setLanguage('en-IN');
      }
    } catch (_) {
      // Requested language isn't installed on this device — fall back
      // to English silently rather than crashing.
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {
        // Even English isn't available — speak() below will no-op.
      }
    }

    try {
      await _tts.speak(stripMarkdownForSpeech(text));
    } catch (_) {
      // No TTS engine/voice available on this device — fail silently.
      // The response is still fully readable on screen.
    }

    if (mounted && _speakingIndex == index) {
      setState(() => _speakingIndex = null);
    }
  }

  void _flagForFollowUp(int index) {
    // Mock state only — no backend call is made (ported as-is from
    // the old CropResultScreen).
    setState(() => _thread[index].isFlagged = true);
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
          .map((e) => StoredMessage(
                isUser: e.isUser,
                text: e.text,
                isCropDiagnosis: e.isCropDiagnosis,
                isFlagged: e.isFlagged,
              ))
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

                              final bool canReplay =
                                  _speakingIndex == null || _speakingIndex == index;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AdvisoryBubble(
                                    text: entry.text,
                                    isSpeaking: _speakingIndex == index,
                                    onReplay:
                                        canReplay ? () => _speak(index, entry.text) : null,
                                  ),
                                  if (entry.isCropDiagnosis) ...[
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 46),
                                      child: entry.isFlagged
                                          ? _FlaggedNotice(districtName: _mockDistrictName)
                                          : OutlinedButton.icon(
                                              onPressed: () => _flagForFollowUp(index),
                                              icon: const Icon(
                                                Icons.support_agent_rounded,
                                                size: 18,
                                              ),
                                              label: const Text('Flag for Expert Follow-up'),
                                            ),
                                    ),
                                  ],
                                ],
                              );
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

class _FlaggedNotice extends StatelessWidget {
  const _FlaggedNotice({required this.districtName});

  final String districtName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OutlinedButton(
          onPressed: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded),
              SizedBox(width: 8),
              Text('Flagged ✓'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: AppColors.green.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Flagged for expert follow-up ✓ Rythu Seva Kendra, $districtName',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
