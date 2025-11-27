import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  final TextEditingController nameC = TextEditingController(
    text: "Sule Sutisna",
  );
  final TextEditingController emailC = TextEditingController(
    text: "sulesutisna25@email.com",
  );
  final TextEditingController phoneC = TextEditingController(
    text: "+62 812-3456-7890",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Profil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===================== HEADER =====================
            // ===================== HEADER PROFIL =====================
            // ===================== HEADER PROFIL =====================
            // ===================== HEADER PROFIL =====================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9E2F), Color(0xFFFFC94A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // FOTO PROFIL
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage("assets/profile.jpg"),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // USERNAME (FIX HEIGHT 24px = tidak berubah)
                  Expanded(
                    child: SizedBox(
                      height:
                          28, // Tinggi fix agar tidak berubah saat edit/tidak edit
                      child: isEditing
                          ? TextField(
                              controller: nameC,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                              cursorColor: Colors.white,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 1.3,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              nameC.text,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ICON TETAP DI POSISI DAN UKURAN YANG SAMA
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () async {
                          if (isEditing) {
                            await saveProfile();
                          }
                          setState(() => isEditing = !isEditing);
                        },
                        child: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          size: 20, // FIXED SIZE
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===================== EMAIL CARD =====================
            _valueCard(
              icon: Icons.email_outlined,
              title: "Email",
              controller: emailC,
              isEditing: isEditing,
            ),

            // ===================== PHONE CARD =====================
            _valueCard(
              icon: Icons.phone_outlined,
              title: "Phone",
              controller: phoneC,
              isEditing: isEditing,
            ),

            // ===================== LOGOUT =====================
            _logoutCard(),
          ],
        ),
      ),
    );
  }

  // =====================================================
  //                 CARD DENGAN TEXTFIELD
  // =====================================================
  Widget _valueCard({
  required IconData icon,
  required String title,
  required TextEditingController controller,
  required bool isEditing,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.black87),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),

              // ===========================================
              //      FIX HEIGHT - TIDAK BERUBAH SAAT EDIT
              // ===========================================
              SizedBox(
                height: 22, // Tinggi FIX untuk text & TextField
                child: isEditing
                    ? TextField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.0, // penting
                        ),
                        cursorColor: Colors.black,
                        decoration: const InputDecoration(
                          isDense: true, // penting
                          contentPadding: EdgeInsets.zero, // penting
                          border: UnderlineInputBorder(),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          controller.text,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.0, // supaya sama tinggi
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  // =====================================================
  //                        LOGOUT
  // =====================================================
  Widget _logoutCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Logout",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  // =====================================================
  //                     SAVE PROFILE (HARDCORE ID = 1)
  // =====================================================
  Future<void> saveProfile() async {
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from("users")
          .update({
            "name": nameC.text,
            "email": emailC.text,
            "phone": phoneC.text,
          })
          .eq("id", 1);

      print("UPDATE SUCCESS");
    } catch (e) {
      print("ERROR UPDATE: $e");
    }
  }
}
