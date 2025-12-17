import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;

class GabungMitraPage extends StatefulWidget {
  const GabungMitraPage({super.key});

  @override
  State<GabungMitraPage> createState() => _GabungMitraPageState();
}

class _GabungMitraPageState extends State<GabungMitraPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController nameC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController contactC = TextEditingController();
  final TextEditingController priceC = TextEditingController();
  final TextEditingController bankC = TextEditingController();
  final TextEditingController rekC = TextEditingController();
  final TextEditingController addressC = TextEditingController();

  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  File? workshopImage;
  Uint8List? _webImageBytes;

  final List<String> days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Ming"];
  final Set<String> selectedDays = {};

  bool tambalBan = true;
  bool gantiOli = false;
  bool serviceMotor = false;
  bool serviceMobil = true;
  bool derek = true;

  bool agree = false;
  bool isSaving = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    if (kIsWeb) {
      _webImageBytes = await file.readAsBytes();
      setState(() {});
    } else {
      setState(() {
        workshopImage = File(file.path);
      });
    }
  }

  Future<void> pickTime(bool isOpen) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFDC000)),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isOpen) {
          openTime = result;
        } else {
          closeTime = result;
        }
      });
    }
  }

  String _dayFromWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return "Sen";
      case 2:
        return "Sel";
      case 3:
        return "Rab";
      case 4:
        return "Kam";
      case 5:
        return "Jum";
      case 6:
        return "Sab";
      case 7:
        return "Ming";
      default:
        return "Sen";
    }
  }

  bool calculateIsOpen() {
    if (openTime == null || closeTime == null) return false;

    final now = DateTime.now();
    final nowDay = _dayFromWeekday(now.weekday);

    if (!selectedDays.contains(nowDay)) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final openMinutes = openTime!.hour * 60 + openTime!.minute;
    final closeMinutes = closeTime!.hour * 60 + closeTime!.minute;

    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFDC000), width: 1.3),
      ),
    );
  }

  Widget _dayChip(String day) {
    final selected = selectedDays.contains(day);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            selectedDays.remove(day);
          } else {
            selectedDays.add(day);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDC000) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          day,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _serviceItem(String name, bool val, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!val),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: val ? const Color(0xFFFDC000) : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: val ? const Color(0xFFFDC000) : Colors.grey.shade400,
                width: 1.3,
              ),
            ),
            child: val
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> saveWorkshop() async {
    if (isSaving) return;

    if (nameC.text.trim().isEmpty ||
        contactC.text.trim().isEmpty ||
        priceC.text.trim().isEmpty ||
        openTime == null ||
        closeTime == null ||
        selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua data wajib.")),
      );
      return;
    }

    if (!agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Setujui syarat & ketentuan terlebih dahulu."),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      String? imageUrl;

      if (!kIsWeb && workshopImage != null) {
        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${p.basename(workshopImage!.path)}";

        final pathInBucket = "workshops/$fileName";

        final result = await supabase.storage
            .from("images")
            .upload(
          pathInBucket,
          workshopImage!,
          fileOptions: const FileOptions(upsert: false),
        );

        if (result == null) {
          throw Exception("Upload gagal! File tidak masuk ke storage.");
        }

        final publicUrl = supabase.storage.from("images").getPublicUrl(pathInBucket);

        if (publicUrl.isEmpty) {
          throw Exception("Public URL gagal dibuat. Cek bucket.");
        }

        imageUrl = publicUrl;
      }

      if (kIsWeb && _webImageBytes != null) {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

        final storagePath = "workshops/$fileName";

        await supabase.storage
            .from("images")
            .uploadBinary(
              storagePath,
              _webImageBytes!,
              fileOptions: const FileOptions(upsert: false),
            );

        final publicUrl = supabase.storage.from("images").getPublicUrl(storagePath);

        imageUrl = publicUrl;
      }

      final position = await getCurrentLocation();

      double? latitude;
      double? longitude;

      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
      } else {
        latitude = null;
        longitude = null;
      }

      final openTimeStr = openTime != null ? formatTimeOfDay(openTime!) : null;
      final closeTimeStr = closeTime != null ? formatTimeOfDay(closeTime!) : null;
      final user = Supabase.instance.client.auth.currentUser;

      final inserted = await supabase
          .from("workshops")
          .insert({
            "bengkelname": nameC.text.trim(),
            "address": addressC.text.trim(),
            "description": descC.text.trim(),
            "contact": contactC.text.trim(),
            "image": imageUrl ?? "",
            "price":
                int.tryParse(priceC.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0,
            "open_time": openTimeStr,
            "close_time": closeTimeStr,
            "latitude": latitude,
            "longitude": longitude,
            "save": false,
            "bank": bankC.text.trim(),
            "nomor_rekening": int.tryParse(rekC.text.trim()) ?? 0,
            "userid": user?.id,
          })
          .select()
          .single();

      final workshopId = inserted["id"];

      List<String> services = [];
      if (tambalBan) services.add("Tambal Ban");
      if (gantiOli) services.add("Ganti Oli");
      if (serviceMotor) services.add("Service Motor");
      if (serviceMobil) services.add("Service Mobil");
      if (derek) services.add("Derek Kendaraan");

      for (final s in services) {
        await supabase.from("service").insert({
          "workshop_id": workshopId,
          "name": s,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil mendaftar sebagai Mitra!")),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard-workshop',
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  String formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDC000),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Gabung menjadi Mitra!",
          style: TextStyle(
            fontFamily: "Euclid",
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isSaving ? null : saveWorkshop,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDC000),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    "Simpan Bengkel",
                    style: TextStyle(
                      fontFamily: "Euclid",
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nama Bengkel",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameC,
                      decoration: _inputDecoration(
                        "Tuliskan Nama Bengkel Anda",
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Alamat Bengkel",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressC,
                      decoration: _inputDecoration(
                        "Tuliskan Alamat Lengkap Bengkel Anda",
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Foto Bengkel",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                        child: _webImageBytes != null
                            ? Image.memory(
                                _webImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : workshopImage != null
                            ? Image.file(
                                workshopImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Deskripsi Bengkel",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descC,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        "Deskripsikan bengkel Anda secara singkat...",
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Kontak Bengkel",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contactC,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration("+62 ....."),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Hari Operasional",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: days
                            .map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: _dayChip(d),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(
                          child: Text(
                            "Jam Buka",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Jam Tutup",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickTime(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                openTime == null
                                    ? "09:00"
                                    : openTime!.format(context),
                                style: const TextStyle(
                                  fontFamily: "Euclid",
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickTime(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                closeTime == null
                                    ? "17:00"
                                    : closeTime!.format(context),
                                style: const TextStyle(
                                  fontFamily: "Euclid",
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Layanan yang Tersedia",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _serviceItem(
                                  "Tambal Ban",
                                  tambalBan,
                                  (v) => setState(() => tambalBan = v),
                                ),
                                const SizedBox(height: 10),
                                _serviceItem(
                                  "Ganti Oli",
                                  gantiOli,
                                  (v) => setState(() => gantiOli = v),
                                ),
                                const SizedBox(height: 10),
                                _serviceItem(
                                  "Service Motor",
                                  serviceMotor,
                                  (v) => setState(() => serviceMotor = v),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                _serviceItem(
                                  "Service Mobil",
                                  serviceMobil,
                                  (v) => setState(() => serviceMobil = v),
                                ),
                                const SizedBox(height: 10),
                                _serviceItem(
                                  "Derek Kendaraan",
                                  derek,
                                  (v) => setState(() => derek = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Harga Jasa Layanan",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceC,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Rp ....."),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      "Bank Account",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bankC,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Nama Bank Anda"),
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      "Nomor Rekening",
                      style: TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: rekC,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        "Tuliskan Nomor Rekening Anda",
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: agree,
                          activeColor: const Color(0xFFFDC000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => setState(() => agree = v!),
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: "Saya setuju dengan ",
                                  style: const TextStyle(
                                    fontFamily: "Euclid",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "syarat & ketentuan",
                                      style: const TextStyle(
                                        fontFamily: "Euclid",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF007AFF),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: " yang berlaku"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dengan mengisi formulir ini, Saya menyatakan bahwa:",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 12),

                          Text(
                            "1. Seluruh informasi yang diberikan kepada URide adalah akurat, sah, dan terbaru.",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "2. Saya memiliki hak serta kewenangan hukum penuh untuk menawarkan seluruh layanan di URide.",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            "3. Seluruh tindakan yang saya lakukan adalah sah dan merupakan perjanjian yang mengikat dengan URide.",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
