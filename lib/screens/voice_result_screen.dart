import 'package:flutter/material.dart';
import '../widgets/advisory_bubbles.dart';

/// Shows the farmer's question and the resulting advisory.
class VoiceResultScreen extends StatelessWidget {
  const VoiceResultScreen({
    super.key,
    required this.query,
    required this.responseText,
    this.language,
  });

  final String query;
  final String responseText;
  final dynamic language;

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
