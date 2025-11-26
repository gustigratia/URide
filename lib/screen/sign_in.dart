import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double scale(double value) => value * (width / 390);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: scale(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: scale(40)),

              // ==============================
              // LOGO URide (PNG VERSION)
              // ==============================
              Image.asset(
                "assets/images/uride.png",
                width: scale(160),
                fit: BoxFit.contain,
              ),

              SizedBox(height: scale(60)),

              // ==============================
              // EMAIL TEXTFIELD
              // ==============================
              Container(
                padding: EdgeInsets.symmetric(horizontal: scale(18)),
                height: scale(55),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scale(14)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: TextField(
                    style: TextStyle(fontSize: scale(14)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Email",
                      hintStyle: TextStyle(
                        fontSize: scale(14),
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(16)),

              // ==============================
              // PASSWORD TEXTFIELD
              // ==============================
              Container(
                padding: EdgeInsets.symmetric(horizontal: scale(18)),
                height: scale(55),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(scale(14)),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        obscureText: !passwordVisible,
                        style: TextStyle(fontSize: scale(14)),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Password",
                          hintStyle: TextStyle(
                            fontSize: scale(14),
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          passwordVisible = !passwordVisible;
                        });
                      },
                      child: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey.shade500,
                        size: scale(22),
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================
              // FORGOT PASSWORD
              // ==============================
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: scale(8)),
                  child: Text(
                    "Lupa Kata Sandi?",
                    style: TextStyle(
                      fontSize: scale(13),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFF7A81B),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(26)),

              // ==============================
              // BUTTON LOGIN
              // ==============================
              GestureDetector(
                child: Container(
                  height: scale(52),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(40)),
                  ),
                  child: Center(
                    child: Text(
                      "Masuk",
                      style: TextStyle(
                        fontSize: scale(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(26)),

              // ==============================
              // REGISTER LINK
              // ==============================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum mempunyai akun? ",
                    style: TextStyle(
                      fontSize: scale(14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    "Daftar",
                    style: TextStyle(
                      fontSize: scale(14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF7A81B),
                    ),
                  ),
                ],
              ),

              SizedBox(height: scale(40)),
            ],
          ),
        ),
      ),
    );
  }
}
