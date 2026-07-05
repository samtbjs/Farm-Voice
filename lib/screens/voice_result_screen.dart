import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/theme/app_colors.dart';
import '../utils/tts_helpers.dart';
import '../models/language_option.dart';
import '../widgets/advisory_bubbles.dart';

/// Shows what the farmer asked (voice or typed) followed by Gemini's
/// advisory response, styled as a small chat conversation. Speaks the
/// advisory aloud automatically, with a replay button on demand.
class VoiceResultScreen extends StatefulWidget {
  const VoiceResultScreen({
    super.key,
    required this.query,
    required this.responseText,
    this.language,
  });

  final String query;
  final String responseText;
  final LanguageOption? language;

  @override
  State<VoiceResultScreen> createState() => _VoiceResultScreenState();
}

class _VoiceResultScreenState extends State<VoiceResultScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _speak();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);

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
      await _tts.speak(widget.responseText);
    } catch (_) {
      // No TTS engine/voice available on this device — fail silently.
      // The response is still fully readable on screen.
    }

    if (mounted) setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Advisory')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            QueryBubble(text: widget.query),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AdvisoryBubble(text: widget.responseText)),
                IconButton(
                  onPressed: _isSpeaking ? null : _speak,
                  icon: Icon(
                    _isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_up_outlined,
                    color: AppColors.green,
                  ),
                  tooltip: 'Replay advisory',
                ),
              ],
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.mic_none_rounded),
              label: const Text('Ask Another Question'),
            ),
          ],
        ),
      ),
    );
  }
}