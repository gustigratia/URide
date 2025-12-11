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

  late Object vehicleId;
  int? vehicleIndex;
  bool hasVehicleId = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)!.settings.arguments as Map?;

    if (args != null && args["id"] != null) {
      vehicleId = args["id"];
      vehicleIndex = args["index"];
      hasVehicleId = true;

      fetchVehicleData();
    }
  }

  // ======================================================
  //                 FETCH DATA
  // ======================================================
  Future<void> fetchVehicleData() async {
    if (!hasVehicleId) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final data = await supabase
        .from("vehicles")
        .select()
        .eq("id", vehicleId)
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
  //                 UPDATE DATA
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
        .eq("id", vehicleId)
        .eq("userid", user.id);

    if (!mounted) return;

    Navigator.pop(context, {
      "updated": true,
      "index": vehicleIndex,
    });
  }

  // ======================================================
  //                 DELETE DATA
  // ======================================================
  Future<void> deleteVehicle() async {
    if (!hasVehicleId) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    await supabase
        .from("vehicles")
        .delete()
        .eq("id", vehicleId)
        .eq("userid", user.id);

    if (!mounted) return;

    Navigator.pop(context, {
      "deleted": true,
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
                    // ====================
                    // INPUT NAMA
                    // ====================
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

                    // ====================
                    // INPUT PLAT
                    // ====================
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

                    // ====================
                    // INPUT KM
                    // ====================
                    const Text(
                      "Kilometer",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _inputField("Masukkan kilometer kendaraan", kilometerC),

                    const SizedBox(height: 28),

                    // ======================================================
                    //                 BUTTON HAPUS (Dialog Putih)
                    // ======================================================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return Dialog(
                                backgroundColor: Colors.white,
                                insetPadding: const EdgeInsets.all(40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 22),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Hapus Kendaraan",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Anda yakin ingin menghapus kendaraan ini? Tindakan ini tidak dapat dibatalkan.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text(
                                              "Batal",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 10),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              "Hapus",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          if (confirm == true) {
                            await deleteVehicle();
                          }
                        },
                        child: const Text(
                          "Hapus Kendaraan",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ======================================================
                    //                 BUTTON SIMPAN
                    // ======================================================
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
