import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadImageTestScreen extends StatefulWidget {
  const UploadImageTestScreen({super.key});

  @override
  State<UploadImageTestScreen> createState() => _UploadImageTestScreenState();
}

class _UploadImageTestScreenState extends State<UploadImageTestScreen> {
  File? _selectedImage;
  String uploadStatus = "";
  String? uploadedUrl;

  final picker = ImagePicker();
  final supabase = Supabase.instance.client;

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> uploadImage() async {
    if (_selectedImage == null) {
      setState(() => uploadStatus = "No image selected");
      return;
    }

    try {
      setState(() => uploadStatus = "Uploading...");

      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${basename(_selectedImage!.path)}";

      final result = await supabase.storage.from('images').upload(
        "workshops/$fileName",
        _selectedImage!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = supabase.storage.from('images').getPublicUrl(result);

      setState(() {
        uploadStatus = "Upload success!";
        uploadedUrl = publicUrl;
      });
    } catch (e) {
      setState(() => uploadStatus = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Image Test"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage == null
                  ? const Center(child: Text("No Image Selected"))
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            // Pick Image Button
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image"),
            ),

            const SizedBox(height: 10),

            // Upload Button
            ElevatedButton(
              onPressed: uploadImage,
              child: const Text("Upload to Supabase"),
            ),

            const SizedBox(height: 20),

            // Status Text
            Text(
              uploadStatus,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // Uploaded URL result
            if (uploadedUrl != null) ...[
              const Text("Image URL:", style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                uploadedUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
