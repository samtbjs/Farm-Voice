import 'package:flutter/material.dart';
import '../widgets/camera_preview_placeholder.dart';

/// Camera screen: a big preview box and a single "Take Photo" button.
///
/// Hook up the real camera plugin and the Gemini vision call inside
/// [_takePhoto].
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  void _takePhoto(BuildContext context) {
    // TODO: capture a real photo, then send it to the Gemini API
    // for crop disease detection and show the result.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Crop')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CameraPreviewPlaceholder(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _takePhoto(context),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Take Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
