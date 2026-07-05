import '../../models/language_option.dart';

/// Maps a farmer-selected [LanguageOption] to the locale string
/// flutter_tts expects for `setLanguage` (e.g. "hi_IN" -> "hi-IN").
///
/// Falls back to "en-IN" when no language has been selected.
String ttsLocaleFor(LanguageOption? language) {
  if (language == null) return 'en-IN';
  return language.localeId.replaceAll('_', '-');
}

/// Strips the lightweight markdown characters MarkdownLiteText renders
/// (bullets, bold markers, headings) so TTS doesn't read them aloud as
/// literal punctuation (e.g. "asterisk", "hash").
String stripMarkdownForSpeech(String text) {
  final buffer = StringBuffer();
  for (final rawLine in text.split('\n')) {
    var line = rawLine.trim();
    if (line.isEmpty) continue;
    // Drop bullet markers at the start of a line.
    line = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
    // Drop heading markers at the start of a line.
    line = line.replaceFirst(RegExp(r'^#+\s*'), '');
    // Strip any remaining bold/italic/heading markers in the line.
    line = line.replaceAll(RegExp(r'[*#]'), '');
    buffer.writeln(line);
  }
  return buffer.toString().trim();
}