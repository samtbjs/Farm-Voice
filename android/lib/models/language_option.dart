/// A single selectable language for the Voice screen dropdown.
class LanguageOption {
  const LanguageOption({required this.code, required this.label});

  final String code;
  final String label;

  /// Mock list — replace/extend once real localization is wired up.
  static const List<LanguageOption> all = [
    LanguageOption(code: 'en', label: 'English (English)'),
    LanguageOption(code: 'hi', label: 'हिन्दी (Hindi)'),
    LanguageOption(code: 'ta', label: 'தமிழ் (Tamil)'),
    LanguageOption(code: 'te', label: 'తెలుగు (Telugu)'),
    LanguageOption(code: 'mr', label: 'मराठी (Marathi)'),
    LanguageOption(code: 'kn', label: 'ಕನ್ನಡ (Kannada)'),
  ];
}
