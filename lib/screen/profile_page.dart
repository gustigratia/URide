import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  
  // Variabel untuk status apakah user punya bengkel
  bool hasWorkshop = false;

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

  Future<void> loadUser() async {
    final supabase = Supabase.instance.client;

    try {
      if (currentUser == null) return;

      emailC.text = currentUser!.email ?? "";

      // 1. Ambil data User
      final userData = await supabase
          .from("users")
          .select()
          .eq("id", currentUser!.id)
          .maybeSingle();

      if (userData != null) {
        firstname = userData["firstname"] ?? "";
        lastname = userData["lastname"] ?? "";
        nameC.text = "$firstname $lastname".trim();
        phoneC.text = userData["phone"] ?? "";
      }

      // 2. Cek apakah user ini sudah punya workshop (bengkel)
      // Kita query ke tabel workshops dimana userid = current user id
      final workshopData = await supabase
          .from("workshops")
          .select("id") // Kita hanya butuh ID untuk memastikan datanya ada
          .eq("userid", currentUser!.id)
          .maybeSingle();

      // Jika workshopData tidak null, berarti user punya bengkel
      if (workshopData != null) {
        hasWorkshop = true;
      } else {
        hasWorkshop = false;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("ERROR LOAD USER: $e");
    }
  }

  Future<void> saveProfile() async {
    final supabase = Supabase.instance.client;

    try {
      List<String> parts = nameC.text.trim().split(" ");
      firstname = parts.first;
      lastname = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      await supabase
          .from("users")
          .update({
            "firstname": firstname,
            "lastname": lastname,
            "phone": phoneC.text,
          })
          .eq("id", currentUser!.id);

      await loadUser();
    } catch (e) {
      print("ERROR UPDATE: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const CircleAvatar(
                      radius: 32,
                      // Pastikan aset gambar ada
                      backgroundImage: AssetImage("assets/profile.jpg"),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 26,
                          child: isEditing
                              ? TextField(
                                  controller: nameC,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 1.2,
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                        width: 1.2,
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        
                        // --- BAGIAN TOMBOL MITRA / BENGKEL SAYA ---
                        GestureDetector(
                          onTap: () {
                            if (hasWorkshop) {
                              Navigator.pushNamed(context, '/dashboard-workshop');
                            } else {
                              Navigator.pushNamed(context, '/join-workshop'); 
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              // Logika text tombol
                              hasWorkshop ? "Bengkel Saya" : "Gabung Jadi Mitra",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        // ------------------------------------------

                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _profileCard(
              icon: Icons.email_outlined,
              title: "Email",
              controller: emailC,
              readOnly: false,
              isEditing: isEditing,
            ),
            _profileCard(
              icon: Icons.phone_outlined,
              title: "Phone",
              controller: phoneC,
              readOnly: false,
              isEditing: isEditing,
            ),
            _logoutCard(),
          ],
        ),
      ),
    );
  }

  // ... (Sisa kode _profileCard dan _logoutCard sama seperti sebelumnya)
  
  Widget _profileCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required bool readOnly,
    required bool isEditing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      // UBAH DARI COLUMN KE ROW AGAR ICON DI KIRI DAN TEXT DI KANAN
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // PENTING: Ini yang bikin icon di tengah vertikal
        children: [
          // 1. BAGIAN ICON
          Icon(icon, color: Colors.black54, size: 24),
          
          const SizedBox(width: 16), // Jarak antara icon dan teks

          // 2. BAGIAN TEXT (JUDUL + ISI)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Judul (Email/Phone)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12, // Sedikit dikecilkan agar proporsional
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4), // Jarak kecil ke input field

                // Input Field / Text Value
                SizedBox(
                  height: 24, // Tinggi area input
                  child: isEditing
                      ? TextField(
                          controller: controller,
                          readOnly: readOnly,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.only(bottom: 4),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54, width: 1),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black54, width: 1),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 1.4),
                            ),
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _logoutCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          "Log Out",
          style: TextStyle(
            color: Colors.red,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () async {
          final supabase = Supabase.instance.client;
          await supabase.auth.signOut();
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/signin',
              (route) => false,
            );
          }
        },
      ),
    );
  }
}