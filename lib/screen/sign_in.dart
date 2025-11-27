import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool passwordVisible = false;
  bool isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _show("Email dan password tidak boleh kosong");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthApiException {
      _show("Email atau password salah atau akun belum terdaftar");
    } catch (e) {
      _show("Login gagal: $e");
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
              SizedBox(height: scale(context, 60)),

              _inputBox(
                context,
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: scale(context, 14)),
                  decoration: _dec("Email", context),
                ),
              ),
              SizedBox(height: scale(context, 16)),

              _inputBox(
                context,
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !passwordVisible,
                        style: TextStyle(fontSize: scale(context, 14)),
                        decoration: _dec("Password", context),
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
                        size: scale(context, 22),
                      ),
                    ),
                  ],
                ),
              ),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/ubah-kata-sandi');
          },
          child: Text(
            "Lupa Kata Sandi?",
            style: TextStyle(
              fontSize: scale(context, 13),
              fontWeight: FontWeight.w500,
              color: const Color(0xFFF7A81B),
            ),
          ),
        ),
      ),
              SizedBox(height: scale(context, 26)),

              GestureDetector(
                onTap: isLoading ? null : _signIn,
                child: Container(
                  height: scale(context, 52),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(context, 40)),
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Loading..." : "Masuk",
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum mempunyai akun? ",
                    style: TextStyle(
                      fontSize: scale(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // nanti diarahkan ke halaman register
                    },
                    child: Text(
                      "Daftar",
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
