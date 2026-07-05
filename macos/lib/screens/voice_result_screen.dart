import 'package:flutter/material.dart';
import '../widgets/advisory_bubbles.dart';

/// Shows what the farmer asked (voice or typed) followed by Gemini's
/// advisory response, styled as a small chat conversation.
class VoiceResultScreen extends StatelessWidget {
  const VoiceResultScreen({
    super.key,
    required this.query,
    required this.responseText,
  });

  final String query;
  final String responseText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Advisory')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            QueryBubble(text: query),
            const SizedBox(height: 18),
            AdvisoryBubble(text: responseText),
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
