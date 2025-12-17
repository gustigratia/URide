import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';

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

  bool isLoading = false;

  double scale(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value * (width / 390);
  }

  Future<void> _updatePassword() async {
    final newPass = _passwordController.text.trim();
    final confirmPass = _confirmController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi.")),
      );
      return;
    }

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 6 karakter.")),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konfirmasi password tidak cocok.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kata sandi berhasil diubah."),
          ),
        );

        await Supabase.instance.client.auth.signOut();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signin,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengubah kata sandi.")),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan tak terduga.")),
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
                fit: BoxFit.contain,
              ),

              SizedBox(height: scale(context, 40)),

              _inputPasswordBox(
                context,
                "Kata sandi baru",
                _passwordController,
                passwordVisible1,
                () => setState(() => passwordVisible1 = !passwordVisible1),
              ),

              SizedBox(height: scale(context, 16)),

              _inputPasswordBox(
                context,
                "Konfirmasi kata sandi baru",
                _confirmController,
                passwordVisible2,
                () => setState(() => passwordVisible2 = !passwordVisible2),
              ),

              SizedBox(height: scale(context, 30)),

              GestureDetector(
                onTap: isLoading ? null : _updatePassword,
                child: Container(
                  height: scale(context, 52),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7A81B),
                    borderRadius: BorderRadius.circular(scale(context, 40)),
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Mengubah..." : "Ubah Kata Sandi",
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
