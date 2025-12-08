import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TambahKendaraanPage extends StatefulWidget {
  const TambahKendaraanPage({super.key});

  @override
  State<TambahKendaraanPage> createState() => _TambahKendaraanPageState();
}

class _TambahKendaraanPageState extends State<TambahKendaraanPage> {
  final TextEditingController namaKendaraanC = TextEditingController();
  final TextEditingController nomorPlatC = TextEditingController();
  final TextEditingController kilometerC = TextEditingController();
  final TextEditingController lastServiceDateC = TextEditingController();

  String selectedType = "motor"; // default

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey("type")) {
      selectedType = args["type"]; // motor / mobil
    }
  }

  Future<void> simpanKendaraan() async {
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = {
      "userid": user.id,
      "vehicletype": selectedType,
      "vehiclename": namaKendaraanC.text,
      "vehiclenumber": nomorPlatC.text,
      "kilometer": kilometerC.text,
      "lastservicedate": lastServiceDateC.text,
    };

    try {
      final response = await supabase
          .from('vehicles')
          .insert(data)
          .select()
          .single();

      final vehicleId = response['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kendaraan berhasil disimpan!")),
      );

      // ➜ KIRIM TYPE + ID
      Navigator.pushNamed(
        context,
        '/vehicle',
        arguments: {"id": vehicleId, "type": selectedType},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Tambah Kendaraan",
          style: TextStyle(
            fontFamily: "Euclid",
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // FORM CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildLabel("Nama Kendaraan"),
                  buildField(
                    "Masukkan nama kendaraan",
                    controller: namaKendaraanC,
                  ),

                  const SizedBox(height: 15),
                  buildLabel("Nomor plat"),
                  buildField(
                    "Masukkan nomor plat kendaraan",
                    controller: nomorPlatC,
                  ),

                  const SizedBox(height: 15),
                  buildLabel("Kilometer"),
                  buildField(
                    "Masukkan kilometer kendaraan",
                    controller: kilometerC,
                  ),

                  const SizedBox(height: 15),
                  buildLabel("Tanggal Servis Terakhir"),
                  buildField(
                    "Masukkan tanggal servis terakhir (YY-MM-DD)",
                    controller: lastServiceDateC,
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: simpanKendaraan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFEB800),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Simpan",
                        style: TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: "Euclid",
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget buildField(String hint, {TextEditingController? controller}) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: "Euclid",
            fontSize: 13,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
