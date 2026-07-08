import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A large circular microphone button used on the Voice screen.
class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording ? AppColors.amber : AppColors.green,
        ),
        alignment: Alignment.center,
        child: Icon(
          isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          size: 72,
          color: Colors.white,
        ),
      ),
    );
  }
}
