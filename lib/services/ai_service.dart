import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const String _apiKey = 'AIzaSyC6Xv2JR0mT8Xu_-HspXYNdRXymGld-EXo';
  late final ChatSession _chat;

  AiService()
    : _chat =
          GenerativeModel(model: 'gemini-2.5-pro', apiKey: _apiKey).startChat();

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      debugPrint('Gemini Response: ${response.text}');
      return response.text ?? 'Could not generate a response.';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Error: $e';
    }
  }
}
