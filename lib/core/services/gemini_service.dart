import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  static const String _functionName = 'gemini';

  static Future<String> chat(String message) async {
    try {
      if (message.trim().isEmpty) {
        return 'Pesan tidak boleh kosong';
      }

      if (Supabase.instance.client.auth.currentUser == null) {
        return 'User belum login';
      }

      final FunctionResponse res = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'prompt': message,
        },
      );

      final data = res.data;
      return data['text'] ?? 'Tidak ada respon dari Gemini';

    } on FunctionException catch (e) {
      final details = e.details;

      if (details is Map && details['error'] != null) {
        return 'Server Error: ${details['error']}';
      }

      return 'Terjadi kesalahan server (Status: ${e.status})';

    } catch (e) {
      return 'Error tidak terduga: $e';
    }
  }
}