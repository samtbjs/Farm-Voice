import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Stand-in used on non-web platforms so the app still compiles.
///
/// Native platforms (Android/iOS/desktop) already get a real camera
/// through `image_picker`'s `ImageSource.camera`, so this should
/// never actually be called there — callers must guard with
/// `kIsWeb` first.
Future<Uint8List?> captureFromWebCamera(BuildContext context) async {
  throw UnsupportedError(
    'captureFromWebCamera is only available when running on the web.',
  );
}
