import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
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

  String selectedType = "motor";

  File? vehicleImage;
  Uint8List? _webImageBytes;
  String? uploadedImageUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey("type")) {
      selectedType = args["type"];
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    if (kIsWeb) {
      _webImageBytes = await file.readAsBytes();
      setState(() {});
    } else {
      vehicleImage = File(file.path);
      setState(() {});
    }
  }

  Future<String?> uploadImage() async {
    final supabase = Supabase.instance.client;

    try {
      if (!kIsWeb && vehicleImage != null) {
        final ext = p.extension(vehicleImage!.path);
        final fileName = "${DateTime.now().millisecondsSinceEpoch}$ext";

        final storagePath = "vehicles/$fileName";

        await supabase.storage
            .from("images")
            .upload(
              storagePath,
              vehicleImage!,
              fileOptions: const FileOptions(upsert: false),
            );

        final publicUrl = supabase.storage
            .from("images")
            .getPublicUrl(storagePath);

        return publicUrl;
      }

      if (kIsWeb && _webImageBytes != null) {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final storagePath = "vehicles/$fileName";

        await supabase.storage
            .from("images")
            .uploadBinary(
              storagePath,
              _webImageBytes!,
              fileOptions: const FileOptions(upsert: false),
            );

        final publicUrl = supabase.storage
            .from("images")
            .getPublicUrl(storagePath);

        return publicUrl;
      }

      return null;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  Future<void> simpanKendaraan() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final imageUrl = await uploadImage();

    final data = {
      "userid": user.id,
      "vehicletype": selectedType,
      "vehiclename": namaKendaraanC.text,
      "vehiclenumber": nomorPlatC.text,
      "kilometer": kilometerC.text,
      "lastservicedate": lastServiceDateC.text,
      "img": imageUrl ?? "",
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
          child: const Icon(
            Icons.arrow_back,
            size: 28,
            color: Colors.black,
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
                  buildLabel("Foto Kendaraan"),
                  const SizedBox(height: 6),

                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        color: const Color(0xFFF8F8F8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _webImageBytes != null
                            ? Image.memory(
                                _webImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : vehicleImage != null
                            ? Image.file(
                                vehicleImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  buildLabel("Nomor Plat"),
                  buildField("Masukkan nomor plat", controller: nomorPlatC),

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

                  const SizedBox(height: 20),

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
