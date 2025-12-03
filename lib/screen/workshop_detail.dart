import 'package:flutter/material.dart';
import 'package:uride/main.dart'; // supabase
import 'package:uride/routes/app_routes.dart';
import 'package:share_plus/share_plus.dart';

class BengkelDetailScreen extends StatelessWidget {
  final int workshopId;

  const BengkelDetailScreen({super.key, required this.workshopId});

  Future<Map<String, dynamic>?> getWorkshopDetail() async {
    final data = await supabase
        .from('workshops')
        .select()
        .eq('id', workshopId)
        .single();
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getWorkshopDetail(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return const Scaffold(
            body: Center(child: Text("Data bengkel tidak ditemukan")),
          );
        }

        final w = snap.data!;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              w['bengkelname'] ?? 'Nama tidak tersedia',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Gambar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(
                              w['image_url'] ??
                                  'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Nama & rating
                      Text(
                        w['bengkelname'] ?? 'Nama tidak tersedia',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '4.7',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Alamat
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w['address'] ?? 'Alamat tidak tersedia',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi
                      Text(
                        w['description'] ?? 'Tidak ada deskripsi',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tombol aksi
                      Row(
                        children: [
                          _SaveButton(workshopId: workshopId),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            color: Colors.amber,
                            onTap: () {
                              final shareText =
                                  'Cek bengkel ${w['bengkelname']} di alamat: ${w['address'] ?? '-'}';
                              Share.share(shareText);
                            },
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.comment_outlined,
                            label: 'Ulas',
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Layanan pilihan
                      const Text(
                        'Layanan pilihan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.build_circle,
                                color: Colors.amber.shade700),
                            const SizedBox(width: 12),
                            const Text(
                              'Derek kendaraan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ServiceItem(icon: Icons.tire_repair, label: 'Tambal Ban'),
                      _ServiceItem(icon: Icons.oil_barrel, label: 'Ganti Oli'),
                      _ServiceItem(icon: Icons.car_repair, label: 'Service Mobil'),
                      const SizedBox(height: 24),

                      // Kontak darurat
                      const Text(
                        'Kontak Darurat :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            w['contact'] ?? 'Tidak tersedia',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Tombol Ajukan Layanan
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.ajukanLayanan,
                        arguments: {
                          'workshopId': workshopId,
                          'workshopName': w['bengkelname'] ?? '',
                          'workshopAddress': w['address'] ?? '',
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajukan Layanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Tombol Simpan dinamis
class _SaveButton extends StatefulWidget {
  final int workshopId;

  const _SaveButton({super.key, required this.workshopId});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool isSaved = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaveStatus();
  }

  Future<void> _loadSaveStatus() async {
    try {
      final data = await supabase
          .from('workshops')
          .select('save')
          .eq('id', widget.workshopId)
          .single();

      setState(() {
        isSaved = data['save'] ?? false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error load save status: $e')),
      );
    }
  }

  Future<void> _toggleSave() async {
    setState(() => isSaved = !isSaved);

    try {
      await supabase
          .from('workshops')
          .update({'save': isSaved})
          .eq('id', widget.workshopId);
    } catch (e) {
      setState(() => isSaved = !isSaved); // rollback jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: _toggleSave,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.amber : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tombol aksi umum
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
