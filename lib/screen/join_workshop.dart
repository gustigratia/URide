import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GabungMitraPage extends StatefulWidget {
  const GabungMitraPage({super.key});

  @override
  State<GabungMitraPage> createState() => _GabungMitraPageState();
}

class _GabungMitraPageState extends State<GabungMitraPage> {
  final supabase = Supabase.instance.client;

  // Controllers
  final TextEditingController nameC = TextEditingController();
  final TextEditingController descC = TextEditingController();
  final TextEditingController contactC = TextEditingController();
  final TextEditingController priceC = TextEditingController();

  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  File? workshopImage;

  final List<String> days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Ming"];
  final Set<String> selectedDays = {};

  bool tambalBan = true;
  bool gantiOli = false;
  bool serviceMotor = false;
  bool serviceMobil = true;
  bool derek = true;

  bool agree = false;
  bool isSaving = false;

  // ------------------------
  // Pick Image
  // ------------------------
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => workshopImage = File(file.path));
    }
  }

  // ------------------------
  // Input Time (keyboard mode)
  // ------------------------
  Future<void> pickTime(bool isOpen) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input, // KEYBOARD MODE
      builder: (context, child) {
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

  // ------------------------
  // Convert weekday → "Sen", "Sel", dst.
  // ------------------------
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

  // ------------------------
  // Hitung apakah bengkel open sekarang
  // ------------------------
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

  // ------------------------
  // INPUT DECORATION
  // ------------------------
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

  // ------------------------
  // DAY CHIP
  // ------------------------
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

  // ------------------------
  // Checkbox layanan
  // ------------------------
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

  // ------------------------
  // SAVE
  // ------------------------
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

      // Upload foto
      if (workshopImage != null) {
        final fileName =
            "workshop_${DateTime.now().millisecondsSinceEpoch}.jpg";

        await supabase.storage
            .from("workshop-images")
            .upload(fileName, workshopImage!);

        imageUrl = supabase.storage
            .from("workshop-images")
            .getPublicUrl(fileName);
      }

      final isOpen = calculateIsOpen();

      // Insert workshop
      final inserted = await supabase
          .from("workshops")
          .insert({
            "bengkelname": nameC.text.trim(),
            "description": descC.text.trim(),
            "contact": contactC.text.trim(),
            "image": imageUrl ?? "",
            "price": priceC.text.trim(),
            "is_open": isOpen, // AUTO OPEN/CLOSE LOGIC
            "save": false,
          })
          .select()
          .single();

      final workshopId = inserted["id"];

      // Insert service
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
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  // ------------------------
  // BUILD UI
  // ------------------------
  @override
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
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
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
                    "Lanjutkan",
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

      // -------------------------
      // PERBAIKAN DI SINI
      // FULL SCROLL VIEW
      // -------------------------
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =======================
              // Nama Bengkel
              // =======================
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
                decoration: _inputDecoration("Bengkel Jaya Makmur"),
              ),

              const SizedBox(height: 16),

              // =======================
              // Foto Bengkel
              // =======================
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: workshopImage == null
                        ? const Center(
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.grey,
                              size: 32,
                            ),
                          )
                        : Image.file(
                            workshopImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =======================
              // Deskripsi Bengkel
              // =======================
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
                  "Menyediakan service dan tambal ban panggilan...",
                ),
              ),

              const SizedBox(height: 16),

              // =======================
              // Kontak
              // =======================
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
                decoration: _inputDecoration("+62 811234567"),
              ),

              const SizedBox(height: 20),

              // =======================
              // Hari operasional
              // =======================
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

              // =======================
              // Jam Buka / Tutup
              // =======================
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      "Jam Buka",
                      style: TextStyle(fontFamily: "Euclid", fontSize: 13),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Jam Tutup",
                      style: TextStyle(fontFamily: "Euclid", fontSize: 13),
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
                          style: const TextStyle(fontFamily: "Euclid"),
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
                          style: const TextStyle(fontFamily: "Euclid"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =======================
              // Layanan yang tersedia
              // =======================
              const Text(
                "Layanan yang Tersedia",
                style: TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
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
                          const SizedBox(height: 8),
                          _serviceItem(
                            "Ganti Oli",
                            gantiOli,
                            (v) => setState(() => gantiOli = v),
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
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

              // =======================
              // Harga
              // =======================
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
                decoration: _inputDecoration("Rp 50.000"),
              ),

              const SizedBox(height: 16),
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

                  // ================================
                  // AGREEMENT UI (PERSIS FIGMA)
                  // ================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: agree,
                        onChanged: (v) => setState(() => agree = v!),
                        activeColor: const Color(0xFFFDC000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            children: [
                              const TextSpan(text: "Saya setuju dengan "),
                              TextSpan(
                                text: "syarat & ketentuan",
                                style: const TextStyle(
                                  color: Color(0xFF007AFF),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: " yang berlaku"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ================================
                  // GRAY SECTION (PERNYATAAN)
                  // ================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF5F5F5,
                      ), // persis warna abu-abu figma
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dengan mengisi formulir ini, Saya menyatakan bahwa:",
                          style: TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 12),

                        // BULLET LIST
                        Text(
                          "1. Seluruh informasi yang diberikan kepada URide adalah akurat, sah, dan terbaru.",
                          style: TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          "2. Saya memiliki hak serta kewenangan hukum penuh untuk menawarkan seluruh layanan di URide.",
                          style: TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          "3. Seluruh tindakan yang Saya lakukan adalah sah dan merupakan perjanjian yang mengikat dengan URide.",
                          style: TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
