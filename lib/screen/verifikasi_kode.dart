import 'package:flutter/material.dart';
import 'package:uride/routes/app_routes.dart';


class VerifikasiKodePage extends StatefulWidget {
  const VerifikasiKodePage({super.key});

  @override
  State<VerifikasiKodePage> createState() => _VerifikasiKodePageState();
}

class _VerifikasiKodePageState extends State<VerifikasiKodePage> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
  }

  Widget _otpBox(BuildContext context, TextEditingController c) {
    return Container(
      width: scale(context, 50),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: scale(context, 28)),
          child: Column(
            children: [
              SizedBox(height: scale(context, 40)),

              // LOGO
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
                  "Kami telah mengirimkan tautan reset ke alpha...@gmail.com. "
                  "Masukkan 5 digit kode yang tertera di email",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              SizedBox(height: scale(context, 32)),

              // OTP BOXES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _controllers
                    .map((c) => _otpBox(context, c))
                    .toList(),
              ),

              SizedBox(height: scale(context, 32)),

              // BUTTON VERIFY
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.buatPasswordBaru);
                },
                child: Container(
                  height: scale(context, 52),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(context, 40)),
                  ),
                  child: Center(
                    child: Text(
                      "Verifikasi Kode",
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

              // RESEND
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
                    onTap: () {
                      // TODO: kirim ulang kode
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
