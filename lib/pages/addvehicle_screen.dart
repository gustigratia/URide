import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  bool isMotor = false;
  bool isMobil = true;

  Future<void> simpanKendaraan() async {
    final supabase = Supabase.instance.client;

    // ambil user yg sedang login
    final userId = 'ac2240e5-5bf9-4314-8892-0f925639bde8';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User tidak ditemukan, harap login ulang")),
      );
      return;
    }

    final data = {
      "userid": userId, // <<< tambahan penting
      "vehicletype": isMotor ? "motor" : "mobil",
      "vehiclename": namaKendaraanC.text,
      "vehiclenumber": nomorPlatC.text,
      "kilometer": kilometerC.text,
      "lastservicedate": lastServiceDateC.text,
    };

    final response = await supabase.from('vehicles').insert(data);

    if (response != null && response.isNotEmpty) {
      // Clear form setelah berhasil save
      namaKendaraanC.clear();
      nomorPlatC.clear();
      kilometerC.clear();
      lastServiceDateC.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kendaraan berhasil disimpan!")),
      );

      // Direct ke halaman VehicleDetailPage()
      Navigator.pushReplacementNamed(context, "/vehicle-detail");
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
        title: Text(
          "Tambah Kendaraan",
          style: GoogleFonts.poppins(
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
            // TAB MOTOR - MOBIL
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // ← BIAR TETAP DI TENGAH
                children: [
                  // ---------------- MOTOR ----------------
                  SizedBox(
                    width: 150,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        isMotor = true;
                        isMobil = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: isMotor
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFED46A),
                                    Color(0xFFFFB000),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMotor ? null : const Color(0xffE3E3E3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              isMotor
                                  ? "images/motor-clicked.png"
                                  : "images/motor-default.png",
                              width: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Motor",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isMotor ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // ---------------- MOBIL ----------------
                  SizedBox(
                    width: 150,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        isMotor = false;
                        isMobil = true;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: isMobil
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFED46A),
                                    Color(0xFFFFB000),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isMobil ? null : const Color(0xffE3E3E3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              isMobil
                                  ? "images/mobil-clicked.png"
                                  : "images/mobil-default.png",
                              width: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Mobil",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isMobil ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

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
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildLabel("Nama Kendaraan"),
                  buildField("Masukkan nama kendaraan",
                      controller: namaKendaraanC),

                  const SizedBox(height: 15),
                  buildLabel("Nomor plat"),
                  buildField("Masukkan nomor plat kendaraan",
                      controller: nomorPlatC),

                  const SizedBox(height: 15),
                  buildLabel("Kilometer"),
                  buildField("Masukkan kilometer kendaraan",
                      controller: kilometerC),

                  const SizedBox(height: 15),
                  buildLabel("Tanggal Servis Terakhir"),
                  buildField("Masukkan tanggal servis terakhir (YY-MM-DD)",
                      controller: lastServiceDateC),

                  const SizedBox(height: 20),

                  Text(
                    "Waktu berkendara",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Catatan : waktu berkendara akan mulai dihitung saat Anda memasukkan informasi kendaraan.",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // BUTTON SIMPAN
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        simpanKendaraan();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFEB800),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
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
            )
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
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
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}
