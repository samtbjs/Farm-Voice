import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Opens the device's webcam in a dialog (via `getUserMedia`) and
/// returns the JPEG bytes of the frame the farmer captures.
///
/// Returns `null` if the farmer cancels the dialog. Throws if the
/// browser has no camera, or the farmer denies camera permission —
/// callers should catch this and show a friendly error, the same way
/// they already do for `image_picker` failures.
Future<Uint8List?> captureFromWebCamera(BuildContext context) async {
  final html.MediaDevices? mediaDevices = html.window.navigator.mediaDevices;
  if (mediaDevices == null) {
    throw StateError('Camera access is not supported in this browser.');
  }

  // Let the actual permission/hardware error (if any) propagate to the
  // caller so it can show its normal "could not open camera" message.
  final html.MediaStream stream = await mediaDevices.getUserMedia({
    'video': {'facingMode': 'environment'},
    'audio': false,
  });

  if (!context.mounted) {
    _stopStream(stream);
    return null;
  }

  final html.VideoElement video = html.VideoElement()
    ..autoplay = true
    ..muted = true
    ..setAttribute('playsinline', 'true')
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover'
    ..srcObject = stream;

  final String viewType =
      'farm-voice-camera-${DateTime.now().microsecondsSinceEpoch}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) => video);

  final Uint8List? bytes = await showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: HtmlElementView(viewType: viewType),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Capture'),
                      onPressed: () {
                        final Uint8List frame = _grabFrame(video);
                        Navigator.of(dialogContext).pop(frame);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  _stopStream(stream);
  return bytes;
}

/// Draws the video element's current frame onto an in-memory canvas
/// and reads it back out as JPEG bytes.
Uint8List _grabFrame(html.VideoElement video) {
  final int width = video.videoWidth;
  final int height = video.videoHeight;
  final html.CanvasElement canvas = html.CanvasElement(
    width: width,
    height: height,
  );
  canvas.context2D.drawImage(video, 0, 0);
  final String dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
  final String base64Data = dataUrl.split(',').last;
  return base64Decode(base64Data);
}

void _stopStream(html.MediaStream stream) {
  for (final html.MediaStreamTrack track in stream.getTracks()) {
    track.stop();
  }
}
