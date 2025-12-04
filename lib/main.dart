import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:URide/pages/orderhistory_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
    await Supabase.initialize(
    url: 'https://mxwxxtaaxksddeijpgbb.supabase.co',
    anonKey: 'sb_publishable_xDF-CQX3wPWcVbm2tpzXdA_0JHyBW4j',
  );

  runApp(const URide());
}

class URide extends StatelessWidget {
  const URide({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Tambah Kendaraan",
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffF5F5F5),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: false,
      ),

      initialRoute: "/order-history",

      routes: {
        "/order-history": (context) => const OrderHistoryScreen(),
      },
    );
  }
}
