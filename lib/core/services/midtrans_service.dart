import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> createMidtransTransaction(int totalFee, int orderId) async {
  final response = await http.post(
    Uri.parse('https://backenduride-production.up.railway.app/create-transaction'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'totalFee': totalFee,
      'flutterOrderId': orderId, // kirim ID record Supabase dari Flutter
    }),
  );

  final data = jsonDecode(response.body);
  if (data.containsKey('redirect_url')) {
    return data['redirect_url'];
  } else {
    throw 'Gagal membuat transaksi: ${data.toString()}';
  }
}
