import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';

class VerifikasiKodePage extends StatefulWidget {
  const VerifikasiKodePage({super.key});

  @override
  State<VerifikasiKodePage> createState() => _VerifikasiKodePageState();
}

class _VerifikasiKodePageState extends State<VerifikasiKodePage> {
  // 8 digit OTP
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());

  bool isLoading = false;

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
  }

  Widget _otpBox(BuildContext context, TextEditingController c) {
    return Container(
      height: scale(context, 55),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale(context, 12)),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: scale(context, 20),
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            final nextIndex = _controllers.indexOf(c) + 1;
            if (nextIndex < _controllers.length) {
              FocusScope.of(context).nextFocus();
            }
          }
        },
      ),
    );
  }

  Future<void> _verifyOTP() async {
    final email = ModalRoute.of(context)!.settings.arguments as String;
    final otp = _controllers.map((e) => e.text).join("");

    if (otp.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi semua 8 digit kode OTP.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      if (res.user != null) {
        Navigator.pushNamed(context, AppRoutes.buatPasswordBaru);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kode OTP salah.")),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP salah: ${e.message}")),
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
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: scale(context, 28)),
          child: Column(
            children: [
              SizedBox(height: scale(context, 40)),
              Image.asset(
                "assets/images/uride.png",
                width: scale(context, 160),
              ),
              SizedBox(height: scale(context, 40)),

              // TITLE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Periksa Email Anda",
                  style: TextStyle(
                    fontSize: scale(context, 22),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: scale(context, 8)),

              // DESCRIPTION
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kami telah mengirimkan kode OTP ke $email.\n"
                  "Masukkan 8 digit kode yang tertera di email.",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              SizedBox(height: scale(context, 32)),

              Row(
                children: List.generate(
                  _controllers.length,
                  (index) => Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: scale(context, 3)),
                      child: _otpBox(context, _controllers[index]),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(context, 32)),

              // BUTTON VERIFY
              GestureDetector(
                onTap: isLoading ? null : _verifyOTP,
                child: Container(
                  height: scale(context, 52),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(context, 40)),
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Memverifikasi..." : "Verifikasi Kode",
                      style: TextStyle(
                        fontSize: scale(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(context, 20)),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum menerima email? ",
                    style: TextStyle(
                      fontSize: scale(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Supabase.instance.client.auth
                          .resetPasswordForEmail(email);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Kode telah dikirim ulang."),
                        ),
                      );
                    },
                    child: Text(
                      "Kirim ulang",
                      style: TextStyle(
                        fontSize: scale(context, 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF7A81B),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: scale(context, 40)),
            ],
          ),
        ),
      ),
    );
  }
}
