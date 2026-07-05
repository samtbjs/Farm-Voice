import 'package:flutter/material.dart';
import '../models/language_option.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/record_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/text_query_field.dart';
import '../widgets/response_placeholder.dart';

/// Voice screen: language dropdown, one big record button, a quiet
/// "or type your question" fallback, and a placeholder for the AI's
/// response.
///
/// [_isRecording] just toggles the button's look for now — hook up
/// real speech capture + the Gemini API behind [_toggleRecording].
/// [_submitTypedQuery] is where the typed-text path should call the
/// same Gemini API and update [_responseText].
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final TextEditingController _queryController = TextEditingController();

  LanguageOption? _selectedLanguage;
  bool _isRecording = false;
  String _responseText = 'AI Response will appear here...';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
    // TODO: start/stop real audio capture here, then call the
    // Gemini API and update _responseText below.
  }

  void _submitTypedQuery(String query) {
    setState(() {
      // TODO: send `query` (+ _selectedLanguage) to the Gemini API and
      // replace this with the real response.
      _responseText = 'You asked: "$query"\n\nAI response will appear here...';
    });
    _queryController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Advisory')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                onTap: _toggleRecording,
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
                onSubmit: _submitTypedQuery,
              ),
              const SizedBox(height: 28),
              ResponsePlaceholder(text: _responseText),
            ],
          ),
        ),
      ),
    );
  }
}
