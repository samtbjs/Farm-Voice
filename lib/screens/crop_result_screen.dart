import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/theme/app_colors.dart';
import '../utils/tts_helpers.dart';
import '../models/language_option.dart';
import '../widgets/markdown_lite_text.dart';

/// Shows the captured crop photo followed by Gemini's diagnosis and
/// remediation steps.
class CropResultScreen extends StatefulWidget {
  const CropResultScreen({
    super.key,
    required this.imageBytes,
    required this.analysisText,
    this.language,
  });

  final Uint8List imageBytes;
  final String analysisText;

  /// Optional — the crop flow doesn't currently have a language
  /// picker, so this defaults to null (TTS falls back to en-IN).
  final LanguageOption? language;

  @override
  State<CropResultScreen> createState() => _CropResultScreenState();
}

class _CropResultScreenState extends State<CropResultScreen> {
  // TODO: replace with real district lookup post-hackathon.
  static const String _mockDistrictName = 'Warangal';

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isFlagged = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakAnalysis() async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);

    try {
      final result = await _tts.setLanguage(ttsLocaleFor(widget.language));
      if (result != 1) {
        await _tts.setLanguage('en-IN');
      }
    } catch (_) {
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {
        // Even English isn't available — speak() below will no-op.
      }
    }

    try {
      await _tts.speak(stripMarkdownForSpeech(widget.analysisText));
    } catch (_) {
      // No TTS engine/voice available on this device — fail silently.
    }

    if (mounted) setState(() => _isSpeaking = false);
  }

  void _flagForFollowUp() {
    // Mock state only — no backend call is made.
    setState(() => _isFlagged = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis Result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.memory(
                  widget.imageBytes,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Gemini's Analysis",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textDark,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _isSpeaking ? null : _speakAnalysis,
                  icon: Icon(
                    _isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.volume_up_outlined,
                    color: AppColors.green,
                  ),
                  tooltip: 'Read analysis aloud',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: MarkdownLiteText(data: widget.analysisText),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan Another Photo'),
            ),
            const SizedBox(height: 12),
            if (!_isFlagged)
              OutlinedButton.icon(
                onPressed: _flagForFollowUp,
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Flag for Expert Follow-up'),
              )
            else ...[
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
              const SizedBox(height: 14),
              Card(
                color: AppColors.green.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Flagged for expert follow-up ✓ Rythu Seva '
                          'Kendra, $_mockDistrictName',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
