import 'dart:async';
import '../secrets.dart';
import 'package:flutter/foundation.dart';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/language_option.dart';

/// One prior turn of a conversation, used to give Gemini memory of
/// what was already said via [GeminiService.getVoiceAdvisory]'s
/// `history` param.
class ChatTurn {
  const ChatTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Wraps all calls to the Gemini API behind two simple methods so the
/// rest of the app never has to think about prompts, models, or error
/// handling directly.
///
/// PASTE YOUR API KEY BELOW before running. Get one at
/// https://aistudio.google.com/app/apikey
class GeminiService {
  GeminiService()
      : _visionModel = GenerativeModel(
          model: _modelName,
          apiKey: _apiKey,
        ),
        _voiceModel = GenerativeModel(
          model: _modelName,
          apiKey: _apiKey,
          systemInstruction: Content.system(_voiceSystemInstruction),
        );

  static const String _apiKey = geminiApiKey;

  static const String _modelName = 'gemini-2.5-flash';

 static const String _voiceSystemInstruction =
    'You are a friendly, knowledgeable agricultural advisor speaking '
    'directly to a farmer in India. Always answer briefly and '
    'accurately — no more than 4-5 short sentences. By default, reply '
    'in the exact same language the farmer used to ask their '
    'question — UNLESS the user message explicitly states which '
    'language to reply in (e.g. "Respond only in English."), in which '
    'case that explicit instruction always takes priority, regardless '
    'of the language the farmer\'s question itself is written in. '
    'Keep the tone warm, simple, and practical, and avoid technical '
    'jargon the farmer would not use themselves.';

  static const String _cropAnalysisPrompt =
      'You are an expert Indian agri-scientist. Analyze this crop leaf '
      'photo. Identify the crop, name the disease if any, and give 3 '
      'short, practical remediation steps in simple bullet points.';

  static const Duration _requestTimeout = Duration(seconds: 30);

  final GenerativeModel _visionModel;
  final GenerativeModel _voiceModel;

  /// Sends [imageBytes] to Gemini for crop-disease analysis and
  /// returns the model's markdown-formatted response.
  ///
  /// If the farmer also typed or spoke something alongside the photo,
  /// pass it as [extraContext] — it's appended to the vision prompt
  /// as additional context (e.g. "the leaves started turning yellow
  /// last week") rather than triggering a separate text-only call, so
  /// Gemini reasons about the photo and the farmer's note together in
  /// one response.
  ///
  /// When [language] is provided, Gemini is explicitly instructed to
  /// respond in that language, just like [getVoiceAdvisory]. When
  /// omitted, it defaults to English.
  ///
  /// Never throws — on any failure (no internet, blocked response,
  /// API error) it returns a short, farmer-readable error message
  /// instead, so the UI never crashes.
  Future<String> analyzeCropImage(
    Uint8List imageBytes, {
    String? extraContext,
    LanguageOption? language,
  }) async {
    try {
      final languageInstruction = language != null
          ? _languageInstruction(language)
          : 'IMPORTANT: No language preference was specified, so respond '
          'only in English.';
      final parts = <Part>[
        TextPart('$_cropAnalysisPrompt\n\n$languageInstruction'),
      ];
      if (extraContext != null && extraContext.trim().isNotEmpty) {
        parts.add(
          TextPart(
            'The farmer also added this note along with the photo: '
            '"${extraContext.trim()}". Take it into account in your '
            'analysis and remediation steps.',
          ),
        );
      }
      parts.add(DataPart('image/jpeg', imageBytes));

      final content = [Content.multi(parts)];

      final response = await _visionModel
          .generateContent(content)
          .timeout(_requestTimeout);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return "I couldn't get a clear reading from this photo. Please "
            'retake it in good daylight, with the leaf filling the '
            'frame, and try again.';
      }
      return text.trim();
    } on TimeoutException {
      return 'The request took too long to respond. Please check your '
          'internet connection and try again.';
    } on GenerativeAIException catch (e) {
      return 'The AI service returned an error: ${e.message}. Please '
          'try again in a moment.';
    } catch (e) {
      return 'Something went wrong while analyzing the photo. Please '
          'check your internet connection and try again.';
    }
  }

  /// Sends [farmerQuery] (typed or transcribed from speech) to Gemini
  /// and returns a short spoken-style advisory.
  ///
  /// [history] is the prior turns of *this* conversation, oldest
  /// first — e.g. built from the screen's `_thread` or from
  /// [StoredMessage]s loaded off a saved conversation. Pass it so
  /// Gemini actually remembers earlier exchanges (like the farmer's
  /// name, or "that crop we discussed") instead of treating every
  /// message as the start of a brand-new conversation. Leave it null
  /// or empty for the first message of a chat.
  ///
  /// When [language] is provided, Gemini is explicitly instructed to
  /// respond in that language by name, rather than relying on it
  /// mirroring the language of [farmerQuery]. When omitted (the
  /// default, for backward compatibility), behavior is unchanged:
  /// Gemini replies in whatever language the farmer asked in.
  ///
  /// Never throws — on any failure it returns a short, farmer-readable
  /// error message instead, so the UI never crashes.
  Future<String> getVoiceAdvisory(
    String farmerQuery, [
    LanguageOption? language,
    List<ChatTurn>? history,
  ]) async {
    try {
      final instruction = language != null
          ? _languageInstruction(language)
          : 'IMPORTANT: No language preference was specified, so respond '
          'only in English regardless of the language used in the '
          'farmer\'s question below.';
      final promptText = '$instruction\n\n$farmerQuery';
      debugPrint('GEMINI PROMPT >>> $promptText');

      final content = <Content>[
        // Earlier turns of this same conversation, so Gemini has
        // memory of what was already said (names, crops, prior
        // advice, etc.) instead of starting fresh every message.
        if (history != null)
          for (final turn in history)
            turn.isUser ? Content.text(turn.text) : Content.model([TextPart(turn.text)]),
        Content.text(promptText),
      ];

      final response = await _voiceModel
          .generateContent(content)
          .timeout(_requestTimeout);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return "I couldn't find a good answer to that. Please try "
            'asking your question again, a little differently.';
      }
      return text.trim();
    } on TimeoutException {
      return 'The request took too long to respond. Please check your '
          'internet connection and try again.';
    } on GenerativeAIException catch (e) {
      return 'The AI service returned an error: ${e.message}. Please '
          'try again in a moment.';
    } catch (e) {
      return 'Something went wrong while getting your advisory. Please '
          'check your internet connection and try again.';
    }
  }

  /// Builds an explicit instruction telling Gemini which language to
  /// reply in, using the English name embedded in [language.label]
  /// (e.g. "हिन्दी (Hindi)" -> "Hindi").
String _languageInstruction(LanguageOption language) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(language.label);
    final languageName = match?.group(1) ?? language.label;
    return 'IMPORTANT: Regardless of the language used in the farmer\'s '
        'question below, you must respond only in $languageName.';
  }
}
