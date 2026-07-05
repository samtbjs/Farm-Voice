import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A large, empty rectangular box standing in for a live camera
/// preview. Swap the child for a real camera widget later.
class CameraPreviewPlaceholder extends StatelessWidget {
  const CameraPreviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.camera_alt_outlined,
          size: 64,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
