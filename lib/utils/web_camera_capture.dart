/// Lets the farmer take a live photo using the browser's webcam when
/// running as a Flutter web app.
///
/// `image_picker`'s "camera" source only works reliably on mobile
/// browsers (it hints the OS to open its native camera app via the
/// file input's `capture` attribute). Desktop browsers largely ignore
/// that hint and just show the same file-picker as "gallery" — which
/// is why "Take Photo" on web looked identical to "Choose from
/// Gallery". This file opens a real camera preview (via
/// `getUserMedia`) in a dialog and lets the farmer snap a frame from
/// it instead.
///
/// The real implementation (`web_camera_capture_web.dart`) only
/// compiles on web, since it uses `dart:html`. On every other
/// platform we swap in the stub below at compile time, so this
/// function should only ever be called after checking `kIsWeb`.
library;
export 'web_camera_capture_stub.dart'
    if (dart.library.html) 'web_camera_capture_web.dart';
