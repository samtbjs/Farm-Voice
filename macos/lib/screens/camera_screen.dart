import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/gemini_service.dart';
import '../widgets/camera_preview_placeholder.dart';
import '../widgets/processing_overlay.dart';
import 'crop_result_screen.dart';

/// Camera screen: a preview box, a "Take Photo" button, and the full
/// capture -> analyze -> navigate flow wired to Gemini.
///
/// Requires camera permission to be declared in
/// `android/app/src/main/AndroidManifest.xml`
/// (`android.permission.CAMERA`) and in `ios/Runner/Info.plist`
/// (`NSCameraUsageDescription`).
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  Uint8List? _capturedImageBytes;
  bool _isProcessing = false;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );

      // User backed out of the camera without taking a photo.
      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();

      setState(() {
        _capturedImageBytes = bytes;
        _isProcessing = true;
      });

      final String analysis = await _geminiService.analyzeCropImage(bytes);

      if (!mounted) return;

      setState(() => _isProcessing = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CropResultScreen(
            imageBytes: bytes,
            analysisText: analysis,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the camera. Please check camera permission '
            'and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Crop')),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _capturedImageBytes == null
                      ? const CameraPreviewPlaceholder()
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Image.memory(
                              _capturedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Take Photo'),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              const Positioned.fill(
                child: ProcessingOverlay(
                  message: 'Analyzing your crop photo…',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
