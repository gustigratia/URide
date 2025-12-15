import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class GeminiService {
  static late final GenerativeModel model;
  static bool _initialized = false;

  static Future<void> initialize() async {
    // Cegah double initialization
    if (_initialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY tidak ditemukan di .env');
    }
    model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    _initialized = true;
  }

  static Future<String> chat(String message) async {
    try {
      // Pastikan sudah initialize sebelum chat
      if (!_initialized) {
        await initialize();
      }

      if (message.trim().isEmpty) {
        return 'Pesan tidak boleh kosong';
      }

      final content = [Content.text(message)];
      final response = await model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Gemini response timeout setelah 30 detik',
        ),
      );

      final text = response.text;
      if (text == null || text.isEmpty) {
        return 'Maaf, Gemini tidak bisa memberikan respon. Coba lagi.';
      }
      return text;
    } on TimeoutException catch (e) {
      return 'Koneksi timeout: ${e.message}. Pastikan internet stabil.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}