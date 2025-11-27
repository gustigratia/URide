import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String? vehicleId;
  int? vehicleIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    vehicleId = args?['id'];
    vehicleIndex = args?['index'];

    if (vehicleId != null) {
      fetchVehicleData();
    }
  }

  Future<void> fetchVehicleData() async {
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('vehicles')
        .select()
        .eq('id', int.parse(vehicleId!))
        .maybeSingle();

    if (data != null) {
      setState(() {
        namaC.text = data['vehiclename'] ?? "";
        platC.text = data['vehiclenumber'] ?? "";
        kilometerC.text = data['kilometer']?.toString() ?? "";
      });
    }
  }

  Future<void> updateVehicle() async {
    final supabase = Supabase.instance.client;

    await supabase.from('vehicles').update({
      'vehiclename': namaC.text.trim(),
      'vehiclenumber': platC.text.trim(),
      'kilometer': int.tryParse(kilometerC.text.trim()) ?? 0,
      'userid': "ac2240e5-5bf9-4314-8892-0f925639bde8",
    }).eq('id', vehicleId!);

    if (mounted) {
      Navigator.pop(context, {
        "updated": true,
        "index": vehicleIndex,
      });
    }
  }

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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 28),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Edit Informasi Kendaraan",
                        style: GoogleFonts.poppins(
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
                    _label("Nama Kendaraan"),
                    _inputField("Masukkan nama kendaraan", namaC),
                    const SizedBox(height: 22),

                    _label("Nomor plat"),
                    _inputField("Masukkan nomor plat kendaraan", platC),
                    const SizedBox(height: 22),

                    _label("Kilometer"),
                    _inputField("Masukkan kilometer kendaraan", kilometerC),
                    const SizedBox(height: 26),

                    
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
                        child: Text(
                          "Simpan",
                          style: GoogleFonts.poppins(
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

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
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
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
