import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';

class UbahKataSandiPage extends StatefulWidget {
  const UbahKataSandiPage({super.key});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  final _emailController = TextEditingController();
  bool isLoading = false;

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
  }

  Future<void> _sendResetOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email tidak boleh kosong")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      //Kirim OTP 
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kode OTP telah dikirim ke email Anda."),
        ),
      );

      Navigator.pushNamed(
        context,
        AppRoutes.verifikasiKode,
        arguments: email,
      );

    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan tak terduga")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: scale(context, 28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: scale(context, 40)),
              Image.asset(
                "assets/images/uride.png",
                width: scale(context, 160),
              ),
              SizedBox(height: scale(context, 40)),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Ubah Kata Sandi",
                  style: TextStyle(
                    fontSize: scale(context, 22),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: scale(context, 8)),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Masukkan email Anda untuk menerima kode OTP reset password",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              SizedBox(height: scale(context, 28)),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email Anda",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: scale(context, 8)),

              Container(
                padding: EdgeInsets.symmetric(horizontal: scale(context, 18)),
                height: scale(context, 55),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scale(context, 14)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Masukkan email Anda",
                  ),
                ),
              ),

              SizedBox(height: scale(context, 30)),

              GestureDetector(
                onTap: isLoading ? null : _sendResetOTP,
                child: Container(
                  height: scale(context, 52),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(context, 40)),
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Mengirim..." : "Kirim Kode OTP",
                      style: TextStyle(
                        fontSize: scale(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(context, 40)),
            ],
          ),
        ),
      ),
    );
  }
}
