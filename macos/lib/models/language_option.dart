/// A single selectable language for the Voice screen dropdown.
///
/// [localeId] is the locale string `speech_to_text` expects when
/// starting a listening session (e.g. `hi_IN`). Actual availability
/// still depends on what speech packs are installed on the device.
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.label,
    required this.localeId,
  });

  final String code;
  final String label;
  final String localeId;

  /// Mock list — replace/extend once real localization is wired up.
  static const List<LanguageOption> all = [
    LanguageOption(code: 'en', label: 'English (English)', localeId: 'en_IN'),
    LanguageOption(code: 'hi', label: 'हिन्दी (Hindi)', localeId: 'hi_IN'),
    LanguageOption(code: 'ta', label: 'தமிழ் (Tamil)', localeId: 'ta_IN'),
    LanguageOption(code: 'te', label: 'తెలుగు (Telugu)', localeId: 'te_IN'),
    LanguageOption(code: 'mr', label: 'मराठी (Marathi)', localeId: 'mr_IN'),
    LanguageOption(code: 'kn', label: 'ಕನ್ನಡ (Kannada)', localeId: 'kn_IN'),
  ];
}
