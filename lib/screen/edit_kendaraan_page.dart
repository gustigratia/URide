import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
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

  // ===================== IMAGE STATE ======================
  String? currentImageUrl; // URL gambar lama
  File? vehicleImage; // mobile/desktop
  Uint8List? webImageBytes; // web
  bool uploading = false;

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
        currentImageUrl = data["img"] ?? "";
      });
    }
  }

  // ======================================================
  //               PICK IMAGE (WEB & MOBILE)
  // ======================================================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    if (kIsWeb) {
      webImageBytes = await file.readAsBytes();
      vehicleImage = null;
    } else {
      vehicleImage = File(file.path);
      webImageBytes = null;
    }

    setState(() {});
  }

  // ======================================================
  //     DELETE OLD IMAGE FROM SUPABASE STORAGE
  // ======================================================
  Future<void> deleteOldImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;

      // base URL bucket
      final bucketUrl = supabase.storage.from("images").getPublicUrl("");

      // remove base URL → dapat path asli
      String path = imageUrl.replaceFirst(bucketUrl, "");

      // hapus "/" diawal jika ada
      if (path.startsWith("/")) {
        path = path.substring(1);
      }

      await supabase.storage.from("images").remove([path]);

      debugPrint("Deleted old image: $path");
    } catch (e) {
      debugPrint("Delete image error: $e");
    }
  }

  // ======================================================
  //         UPLOAD NEW IMAGE TO SUPABASE STORAGE
  // ======================================================
  Future<String?> uploadImage() async {
    final supabase = Supabase.instance.client;

    try {
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}.jpg";
      String storagePath = "vehicles/$fileName";

      // WEB
      if (kIsWeb && webImageBytes != null) {
        await supabase.storage.from("images").uploadBinary(
              storagePath,
              webImageBytes!,
              fileOptions: const FileOptions(upsert: false),
            );

        return supabase.storage.from("images").getPublicUrl(storagePath);
      }

      // MOBILE / DESKTOP
      if (!kIsWeb && vehicleImage != null) {
        await supabase.storage.from("images").upload(
              storagePath,
              vehicleImage!,
              fileOptions: const FileOptions(upsert: false),
            );

        return supabase.storage.from("images").getPublicUrl(storagePath);
      }

      return null;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  // ======================================================
  //                    UPDATE VEHICLE
  // ======================================================
  Future<void> updateVehicle() async {
    if (!hasVehicleId) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    String newImageUrl = currentImageUrl ?? "";

    bool hasNewImage = (vehicleImage != null || webImageBytes != null);

    if (hasNewImage) {
      final uploadedUrl = await uploadImage();

      if (uploadedUrl != null) {
        // Hapus file lama dari storage
        await deleteOldImage(currentImageUrl);

        newImageUrl = uploadedUrl;
      }
    }

    await supabase
        .from("vehicles")
        .update({
          "vehiclename": namaC.text.trim(),
          "vehiclenumber": platC.text.trim(),
          "kilometer": int.tryParse(kilometerC.text.trim()) ?? 0,
          "img": newImageUrl,
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
  //                    DELETE VEHICLE
  // ======================================================
  Future<void> deleteVehicle() async {
    if (!hasVehicleId) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    // hapus gambar dulu
    await deleteOldImage(currentImageUrl);

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

              // FORM CARD
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
                      "Foto Kendaraan",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          color: const Color(0xFFF3F3F3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: webImageBytes != null
                              ? Image.memory(webImageBytes!, fit: BoxFit.cover)
                              : vehicleImage != null
                                  ? Image.file(vehicleImage!, fit: BoxFit.cover)
                                  : (currentImageUrl != null &&
                                          currentImageUrl!.isNotEmpty)
                                      ? Image.network(currentImageUrl!,
                                          fit: BoxFit.cover)
                                      : const Center(
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                        ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    _label("Nama Kendaraan"),
                    _inputField("Masukkan nama kendaraan", namaC),
                    const SizedBox(height: 20),

                    _label("Nomor Plat"),
                    _inputField("Masukkan nomor plat kendaraan", platC),
                    const SizedBox(height: 20),

                    _label("Kilometer"),
                    _inputField("Masukkan kilometer", kilometerC),
                    const SizedBox(height: 28),

                    // DELETE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: deleteVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Hapus Kendaraan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Simpan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
