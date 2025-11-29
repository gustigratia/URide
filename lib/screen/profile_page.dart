import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();

  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = Supabase.instance.client.auth.currentUser;
    loadUser();
  }

  // ======================================================
  //                    LOAD USER DATA
  // ======================================================
  Future<void> loadUser() async {
    final supabase = Supabase.instance.client;

    try {
      if (currentUser == null) return;

      // EMAIL dari auth.users
      emailC.text = currentUser!.email ?? "";

      // Ambil data tambahan dari public.users
      final data = await supabase
          .from("users")
          .select()
          .eq("id", currentUser!.id)
          .maybeSingle();

      if (data != null) {
        nameC.text = data["username"] ?? "";
        phoneC.text = data["phone"] ?? "";
      }

      print("LOAD SUCCESS: $data");
    } catch (e) {
      print("ERROR LOAD USER: $e");
    }
  }

  // ======================================================
  //                    SAVE PROFILE
  // ======================================================
  Future<void> saveProfile() async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from("users").update({
        "username": nameC.text,
        "phone": phoneC.text,
      }).eq("id", currentUser!.id);

      print("UPDATE SUCCESS");
    } catch (e) {
      print("ERROR UPDATE: $e");
    }
  }

  // ======================================================
  //                        UI
  // ======================================================
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
            // ======================================================
            // HEADER PROFILE
            // ======================================================
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
                children: [
                  // PHOTO
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

                  // USERNAME
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: isEditing
                          ? TextField(
                              controller: nameC,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            )
                          : Text(
                              nameC.text,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // EDIT / CHECK
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
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // EMAIL (read-only karena email dari auth)
            _valueCard(
              icon: Icons.email_outlined,
              title: "Email",
              controller: emailC,
              isEditing: false, // email tidak bisa diedit
            ),

            // PHONE
            _valueCard(
              icon: Icons.phone_outlined,
              title: "Phone",
              controller: phoneC,
              isEditing: isEditing,
            ),

            // LOGOUT BUTTON
            _logoutCard(),
          ],
        ),
      ),
    );
  }

  // ======================================================
  //                     CARD FIELD
  // ======================================================
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
                isEditing
                    ? TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: UnderlineInputBorder(),
                        ),
                      )
                    : Text(
                        controller.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  //                      LOGOUT
  // ======================================================
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
            color: Colors.red,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () async {
          await Supabase.instance.client.auth.signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/sign-in");
          }
        },
      ),
    );
  }
}
