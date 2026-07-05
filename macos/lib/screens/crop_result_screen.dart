import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/markdown_lite_text.dart';

/// Shows the captured crop photo followed by Gemini's diagnosis and
/// remediation steps.
class CropResultScreen extends StatelessWidget {
  const CropResultScreen({
    super.key,
    required this.imageBytes,
    required this.analysisText,
  });

  final Uint8List imageBytes;
  final String analysisText;

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
                  imageBytes,
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
                Text(
                  "Gemini's Analysis",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDark,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: MarkdownLiteText(data: analysisText),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Scan Another Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
