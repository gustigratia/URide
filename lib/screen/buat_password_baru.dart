import 'package:flutter/material.dart';

class BuatPasswordBaruPage extends StatefulWidget {
  const BuatPasswordBaruPage({super.key});

  @override
  State<BuatPasswordBaruPage> createState() => _BuatPasswordBaruPageState();
}

class _BuatPasswordBaruPageState extends State<BuatPasswordBaruPage> {
  bool passwordVisible1 = false;
  bool passwordVisible2 = false;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

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

              // LOGO
              Image.asset(
                "assets/images/uride.png",
                width: scale(context, 160),
                fit: BoxFit.contain,
              ),

              SizedBox(height: scale(context, 40)),

              _inputPasswordBox(
                context,
                "Kata sandi baru",
                _passwordController,
                passwordVisible1,
                () {
                  setState(() {
                    passwordVisible1 = !passwordVisible1;
                  });
                },
              ),

              SizedBox(height: scale(context, 16)),

              _inputPasswordBox(
                context,
                "Konfirmasi kata sandi baru",
                _confirmController,
                passwordVisible2,
                () {
                  setState(() {
                    passwordVisible2 = !passwordVisible2;
                  });
                },
              ),

              SizedBox(height: scale(context, 30)),

              // BUTTON
              GestureDetector(
                onTap: () {
                  // nanti isi logic set password
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

  Widget _inputPasswordBox(
    BuildContext context,
    String hint,
    TextEditingController controller,
    bool visible,
    VoidCallback onToggle,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scale(context, 18)),
      height: scale(context, 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale(context, 14)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !visible,
              style: TextStyle(fontSize: scale(context, 14)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: scale(context, 14),
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade500,
              size: scale(context, 22),
            ),
          ),
        ],
      ),
    );
  }
}
