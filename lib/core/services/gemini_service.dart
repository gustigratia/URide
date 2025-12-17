import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  static const String _functionName = 'gemini';

  static Future<String> chat(String message) async {
    try {
      if (message.trim().isEmpty) {
        return 'Pesan tidak boleh kosong';
      }

      // Cek sesi login
      if (Supabase.instance.client.auth.currentUser == null) {
        return 'User belum login';
      }

      // PERBAIKAN 1: Tambahkan .client sebelum .functions
      final FunctionResponse res = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {
          'prompt': message,
        },
      );

      final data = res.data;
      return data['text'] ?? 'Tidak ada respon dari Gemini';

    } on FunctionException catch (e) {
      // PERBAIKAN 2: Handling error FunctionException yang benar
      // 'details' berisi response JSON dari Edge Function (jika ada)
      // 'status' berisi HTTP status code (misal 500, 400)

      final details = e.details;

      if (details is Map && details['error'] != null) {
        return 'Server Error: ${details['error']}';
      }

      // Jika details bukan map atau tidak ada field error, tampilkan status code saja
      return 'Terjadi kesalahan server (Status: ${e.status})';

    } catch (e) {
      return 'Error tidak terduga: $e';
    }
  }
}