import 'package:flutter/material.dart';
import 'package:uride/routes/app_routes.dart';

class UbahKataSandiPage extends StatefulWidget {
  const UbahKataSandiPage({super.key});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  final _emailController = TextEditingController();

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
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

              // LOGO URide
              Image.asset(
                "assets/images/uride.png",
                width: scale(context, 160),
                fit: BoxFit.contain,
              ),

              SizedBox(height: scale(context, 40)),

              // TITLE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Ubah Kata Sandi",
                  style: TextStyle(
                    fontSize: scale(context, 22),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),

              SizedBox(height: scale(context, 8)),

              // DESCRIPTION
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Masukkan email Anda untuk mengatur ulang kata sandi",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              SizedBox(height: scale(context, 28)),

              // LABEL EMAIL
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email Anda",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: scale(context, 8)),

              // EMAIL TEXTFIELD
              Container(
                padding: EdgeInsets.symmetric(horizontal: scale(context, 18)),
                height: scale(context, 55),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scale(context, 14)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: scale(context, 14)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Masukkan email Anda",
                      hintStyle: TextStyle(
                        fontSize: scale(context, 14),
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(context, 30)),

              // BUTTON RESET PASSWORD
              GestureDetector(
                onTap: () {
                Navigator.pushNamed(context, AppRoutes.verifikasiKode);                
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
                      "Ubah Kata Sandi",
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
