import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/language_option.dart';
import '../services/gemini_service.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/record_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/text_query_field.dart';
import '../widgets/response_placeholder.dart';
import '../widgets/processing_overlay.dart';
import 'voice_result_screen.dart';

/// Voice screen: language dropdown, one big record button, a quiet
/// "or type your question" fallback, and the full
/// listen/type -> Gemini -> Results flow.
///
/// Requires microphone permission to be declared in
/// `android/app/src/main/AndroidManifest.xml`
/// (`android.permission.RECORD_AUDIO`) and in `ios/Runner/Info.plist`
/// (`NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`).
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final TextEditingController _queryController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiService _geminiService = GeminiService();

  LanguageOption? _selectedLanguage;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _speechAvailable = false;
  String _responseText = 'AI Response will appear here...';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _queryController.dispose();
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

  Future<void> _toggleRecording() async {
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
      localeId: _selectedLanguage?.localeId,
      onResult: (result) {
        if (result.finalResult) {
          final recognizedText = result.recognizedWords.trim();
          setState(() => _isRecording = false);
          if (recognizedText.isNotEmpty) {
            _handleQuery(recognizedText);
          }
        }
      },
    );
  }

  void _submitTypedQuery(String query) {
    _queryController.clear();
    FocusScope.of(context).unfocus();
    _handleQuery(query);
  }

  Future<void> _handleQuery(String query) async {
    setState(() => _isProcessing = true);

    final response = await _geminiService.getVoiceAdvisory(query);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _responseText = response;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceResultScreen(
          query: query,
          responseText: response,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Advisory')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  LanguageDropdown(
                    selected: _selectedLanguage,
                    onChanged: (language) {
                      if (language != null) {
                        setState(() => _selectedLanguage = language);
                      }
                    },
                  ),
                  const SizedBox(height: 36),
                  RecordButton(
                    isRecording: _isRecording,
                    onTap: _isProcessing ? () {} : _toggleRecording,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isRecording ? 'Listening… tap to stop' : 'Tap to speak',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  const OrDivider(),
                  const SizedBox(height: 16),
                  TextQueryField(
                    controller: _queryController,
                    onSubmit: _isProcessing ? (_) {} : _submitTypedQuery,
                  ),
                  const SizedBox(height: 28),
                  ResponsePlaceholder(text: _responseText),
                ],
              ),
            ),
            if (_isProcessing)
              const Positioned.fill(
                child: ProcessingOverlay(
                  message: 'Getting your advisory…',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
