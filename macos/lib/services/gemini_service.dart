import 'dart:async';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

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

  /// TODO: paste your Gemini API key here before building.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  static const String _modelName = 'gemini-1.5-flash';

  static const String _voiceSystemInstruction =
      'You are a friendly, knowledgeable agricultural advisor speaking '
      'directly to a farmer in India. Always answer briefly and '
      'accurately — no more than 4-5 short sentences. Reply in the '
      'exact same language the farmer used to ask their question. '
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
  /// Never throws — on any failure (no internet, blocked response,
  /// API error) it returns a short, farmer-readable error message
  /// instead, so the UI never crashes.
  Future<String> analyzeCropImage(Uint8List imageBytes) async {
    try {
      final content = [
        Content.multi([
          TextPart(_cropAnalysisPrompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

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
  /// and returns a short spoken-style advisory in the same language
  /// the farmer used.
  ///
  /// Never throws — on any failure it returns a short, farmer-readable
  /// error message instead, so the UI never crashes.
  Future<String> getVoiceAdvisory(String farmerQuery) async {
    try {
      final content = [Content.text(farmerQuery)];

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
}
