import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Renders Gemini's lightly-markdown-formatted text (headings marked
/// with `**bold**`, bullet lines starting with `-`/`*`/`•`) using
/// plain Flutter widgets — no external markdown package required.
///
/// This is intentionally simple: it covers the handful of patterns
/// Gemini reliably produces (bold lines, bullet lists, plain
/// paragraphs) rather than full CommonMark support.
class MarkdownLiteText extends StatelessWidget {
  const MarkdownLiteText({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final lines = data.split('\n').where((line) => line.trim().isNotEmpty);
    final bodyStyle = Theme.of(context).textTheme.bodyLarge;
    final boldStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rawLine in lines) _buildLine(rawLine, bodyStyle, boldStyle),
      ],
    );
  }

  Widget _buildLine(String rawLine, TextStyle? bodyStyle, TextStyle? boldStyle) {
    final trimmed = rawLine.trim();
    final isBullet = trimmed.startsWith('-') ||
        trimmed.startsWith('*') ||
        trimmed.startsWith('•');
    final content = isBullet
        ? trimmed.replaceFirst(RegExp(r'^[-*•]\s*'), '')
        : trimmed;
    final isBold = content.startsWith('**') && content.endsWith('**');
    final cleanContent = isBold
        ? content.substring(2, content.length - 2)
        : content.replaceAll('**', '');

    if (isBullet) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 10),
              child: Icon(Icons.circle, size: 6, color: AppColors.green),
            ),
            Expanded(
              child: Text(
                cleanContent,
                style: isBold ? boldStyle : bodyStyle,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        cleanContent,
        style: isBold ? boldStyle : bodyStyle,
      ),
    );
  }
}
