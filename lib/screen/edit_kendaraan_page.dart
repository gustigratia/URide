import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditKendaraanPage extends StatefulWidget {
  const EditKendaraanPage({super.key});

  @override
  State<EditKendaraanPage> createState() => _EditKendaraanPageState();
}

class _EditKendaraanPageState extends State<EditKendaraanPage> {
  final namaC = TextEditingController();
  final platC = TextEditingController();
  final kilometerC = TextEditingController();

  late Object vehicleId;       // ✔ FIX: Tidak nullable
  int? vehicleIndex;
  bool hasVehicleId = false;   // ✔ Untuk memastikan sebelum query

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as Map?;

    if (args != null && args["id"] != null) {
      vehicleId = args["id"];          // ✔ langsung assign Object
      vehicleIndex = args["index"];
      hasVehicleId = true;

      fetchVehicleData();              // ✔ fetch setelah ID terisi
    }
  }

  // ======================================================
  //                 FETCH DATA KENDARAAN
  // ======================================================
  Future<void> fetchVehicleData() async {
    if (!hasVehicleId) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final data = await supabase
        .from("vehicles")
        .select()
        .eq("id", vehicleId)           // ✔ aman, non-null
        .eq("userid", user.id)
        .maybeSingle();

    if (data != null) {
      setState(() {
        namaC.text = data["vehiclename"] ?? "";
        platC.text = data["vehiclenumber"] ?? "";
        kilometerC.text = data["kilometer"]?.toString() ?? "";
      });
    }
  }

  // ======================================================
  //                 UPDATE DATA KENDARAAN
  // ======================================================
  Future<void> updateVehicle() async {
    if (!hasVehicleId) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase
        .from("vehicles")
        .update({
          "vehiclename": namaC.text.trim(),
          "vehiclenumber": platC.text.trim(),
          "kilometer": int.tryParse(kilometerC.text.trim()) ?? 0,
        })
        .eq("id", vehicleId)           // ✔ aman
        .eq("userid", user.id);        // ✔ hanya kendaraan milik user

    if (!mounted) return;

    Navigator.pop(context, {
      "updated": true,
      "index": vehicleIndex,
    });
  }

  // ======================================================
  //                         UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 28),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Edit Informasi Kendaraan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nama Kendaraan",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _inputField("Masukkan nama kendaraan", namaC),
                    const SizedBox(height: 22),

                    const Text(
                      "Nomor plat",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _inputField("Masukkan nomor plat kendaraan", platC),
                    const SizedBox(height: 22),

                    const Text(
                      "Kilometer",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _inputField("Masukkan kilometer kendaraan", kilometerC),
                    const SizedBox(height: 26),

                    const Text(
                      "Waktu berkendara",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      "Catatan : waktu berkendara akan mulai dihitung saat Anda memasukkan informasi kendaraan.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed: updateVehicle,
                        child: const Text(
                          "Simpan",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
