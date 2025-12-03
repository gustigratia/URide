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

  String firstname = "";
  String lastname = "";

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

      // Email dari auth
      emailC.text = currentUser!.email ?? "";

      // Ambil data dari public.users
      final data = await supabase
          .from("users")
          .select()
          .eq("id", currentUser!.id)
          .maybeSingle();

      if (data != null) {
        firstname = data["firstname"] ?? "";
        lastname = data["lastname"] ?? "";

        nameC.text = "$firstname $lastname".trim();
        phoneC.text = data["phone"] ?? "";
      }

      setState(() {});
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
      // Pisahkan nama menjadi firstname & lastname
      List<String> parts = nameC.text.trim().split(" ");
      firstname = parts.isNotEmpty ? parts.first : "";
      lastname = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      await supabase.from("users").update({
        "firstname": firstname,
        "lastname": lastname,
        "phone": phoneC.text,
      }).eq("id", currentUser!.id);

      print("UPDATE SUCCESS");

      await loadUser(); // refresh UI

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

      bottomNavigationBar: _bottomNavBar(),

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
                crossAxisAlignment: CrossAxisAlignment.center,
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

                  // NAME FIELD
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: nameC,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              isDense: true,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 1.5),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                          )
                        : Text(
                            nameC.text,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(width: 12),

                  // EDIT BUTTON
                  GestureDetector(
                    onTap: () async {
                      if (isEditing) await saveProfile();
                      setState(() => isEditing = !isEditing);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // EMAIL FIELD (read-only)
            _valueCard(
              icon: Icons.email_outlined,
              title: "Email",
              controller: emailC,
              isEditing: isEditing,
              readOnly: true,
            ),

            // PHONE FIELD
            _valueCard(
              icon: Icons.phone_outlined,
              title: "Phone",
              controller: phoneC,
              isEditing: isEditing,
              readOnly: false,
            ),

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
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          isEditing
              ? TextField(
                  controller: controller,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
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

  // ======================================================
  //                   BOTTOM NAVIGATION BAR
  // ======================================================
  Widget _bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (i) {
        if (i == 0) Navigator.pushNamed(context, "/home");
        if (i == 1) Navigator.pushNamed(context, "/vehicle");
        if (i == 2) Navigator.pushNamed(context, "/profile");
      },
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.motorcycle_outlined),
          label: "Kendaraan",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profil",
        ),
      ],
    );
  }
}
