import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool passwordVisible = false;
  bool confirmVisible = false;
  bool isLoading = false;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
  }

  Future<void> _signUp() async {
    if (_firstName.text.isEmpty ||
        _lastName.text.isEmpty ||
        _phone.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty ||
        _confirmPassword.text.isEmpty) {
      _show("Semua field harus diisi");
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _show("Konfirmasi password tidak sama");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text.trim(),
        data: {
          "first_name": _firstName.text.trim(),
          "last_name": _lastName.text.trim(),
          "phone": _phone.text.trim(),
        },
      );

      if (response.user != null) {
        _show("Registrasi berhasil! Silakan verifikasi email Anda.");
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } on AuthApiException catch (_) {
      _show("Registrasi gagal. Cek email atau password Anda.");
    } catch (e) {
      _show("Terjadi kesalahan: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: scale(context, 40)),
              Image.asset(
                "assets/images/uride.png",
                width: scale(context, 160),
                fit: BoxFit.contain,
              ),
              SizedBox(height: scale(context, 50)),

              // =============================
              // NAMA DEPAN
              // =============================
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nama Lengkap",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 6),

              _inputBox(
                context,
                TextField(
                  controller: _firstName,
                  style: TextStyle(fontSize: scale(context, 14)),
                  decoration: _dec("Nama depan", context),
                ),
              ),
              SizedBox(height: scale(context, 10)),

              _inputBox(
                context,
                TextField(
                  controller: _lastName,
                  style: TextStyle(fontSize: scale(context, 14)),
                  decoration: _dec("Nama belakang", context),
                ),
              ),
              SizedBox(height: scale(context, 20)),

              // =============================
              // PHONE
              // =============================
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nomor Telepon",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 6),

              _inputBox(
                context,
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: scale(context, 14)),
                  decoration: _dec("+62      8123456789", context),
                ),
              ),
              SizedBox(height: scale(context, 20)),

              // =============================
              // EMAIL
              // =============================
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 6),

              _inputBox(
                context,
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: scale(context, 14)),
                  decoration: _dec("Email", context),
                ),
              ),
              SizedBox(height: scale(context, 20)),

              // =============================
              // PASSWORD
              // =============================
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kata Sandi",
                  style: TextStyle(
                    fontSize: scale(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 6),

              _inputBox(
                context,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _password,
                        obscureText: !passwordVisible,
                        style: TextStyle(fontSize: scale(context, 14)),
                        decoration: _dec("Kata Sandi", context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => passwordVisible = !passwordVisible);
                      },
                      child: Icon(
                        passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey.shade500,
                        size: scale(context, 22),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: scale(context, 12)),

              _inputBox(
                context,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _confirmPassword,
                        obscureText: !confirmVisible,
                        style: TextStyle(fontSize: scale(context, 14)),
                        decoration: _dec("Konfirmasi Kata Sandi", context),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => confirmVisible = !confirmVisible);
                      },
                      child: Icon(
                        confirmVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey.shade500,
                        size: scale(context, 22),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: scale(context, 26)),

              // =============================
              // BUTTON DAFTAR
              // =============================
              GestureDetector(
                onTap: isLoading ? null : _signUp,
                child: Container(
                  height: scale(context, 52),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(context, 40)),
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Loading..." : "Daftar",
                      style: TextStyle(
                        fontSize: scale(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: scale(context, 26)),

              // =============================
              // PUNYA AKUN? LOGIN
              // =============================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sudah mempunyai akun? ",
                    style: TextStyle(
                      fontSize: scale(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                    child: Text(
                      "Masuk",
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

  // =============================
  // UI COMPONENTS
  // =============================

  Widget _inputBox(BuildContext context, Widget child) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scale(context, 18)),
      height: scale(context, 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scale(context, 14)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  InputDecoration _dec(String hint, BuildContext context) {
    return InputDecoration(
      border: InputBorder.none,
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: scale(context, 14),
        color: Colors.grey.shade400,
      ),
    );
  }
}
