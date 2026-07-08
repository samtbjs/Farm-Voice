import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'markdown_lite_text.dart';

/// The farmer's own question, shown as a plain right-aligned bubble.
///
/// If [imageBytes] is provided (the farmer attached a crop photo,
/// with or without typed/spoken text alongside it), a small thumbnail
/// is shown above the text so the conversation reflects exactly what
/// was sent.
class QueryBubble extends StatelessWidget {
  const QueryBubble({super.key, required this.text, this.imageBytes});

  final String text;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  imageBytes!,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'You asked: $text',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gemini's advisory response, shown as a left-aligned green-tinted
/// bubble with a small AI avatar.
///
/// [text] is rendered with [MarkdownLiteText] since crop-diagnosis
/// responses come back with light markdown formatting (bold labels,
/// bullet remediation steps).
class AdvisoryBubble extends StatelessWidget {
  const AdvisoryBubble({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.10),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: MarkdownLiteText(data: text),
          ),
        ),
      ],
    );
  }
}
