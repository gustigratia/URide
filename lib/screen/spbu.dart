import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';
import 'package:geolocator/geolocator.dart'; // 1. Import Geolocator

class SPBUListScreen extends StatefulWidget {
  const SPBUListScreen({Key? key}) : super(key: key);

  @override
  State<SPBUListScreen> createState() => _SPBUListScreenState();
}

class _SPBUListScreenState extends State<SPBUListScreen> {
  // 2. Ubah default filter atau biarkan 'Buka', di sini saya ubah ke 'Terdekat' agar langsung terlihat
  String selectedFilter = 'Terdekat'; 
  List<SPBUModel> _allSpbuList = [];
  bool _isLoading = true;
  
  // 3. Variable untuk Lokasi User
  Position? _userPosition;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData(); // 4. Panggil init data gabungan
    
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // 5. Fungsi inisialisasi urut: Cari Lokasi -> Ambil Data SPBU
  Future<void> _initData() async {
    await _determinePosition();
    await _fetchSPBU();
  }

  // 6. Logika mendapatkan lokasi user (Geolocator)
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _userPosition = pos;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // 7. Fetch Data & Hitung Jarak
  Future<void> _fetchSPBU() async {
    try {
      final response = await Supabase.instance.client
          .from('spbu')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        List<SPBUModel> tempList = response
            .map<SPBUModel>((data) => SPBUModel.fromJson(data))
            .toList();

        // Hitung jarak jika lokasi user ditemukan
        if (_userPosition != null) {
          for (var spbu in tempList) {
            double dist = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              spbu.latitude,
              spbu.longitude,
            );
            spbu.distanceMeters = dist; // Set jarak ke model
          }
        }

        setState(() {
          _allSpbuList = tempList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching SPBU: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 8. Logika Filtering & Sorting Updated
  List<SPBUModel> getFilteredList() {
    List<SPBUModel> filtered = List.from(_allSpbuList);

    // Filter Logic
    if (selectedFilter == 'Buka') {
      filtered = filtered.where((e) => e.isCurrentlyOpen).toList();
    } else if (selectedFilter == 'Terdekat') { 
      // LOGIC BARU: Sorting berdasarkan jarak
      filtered.sort((a, b) {
        double distA = a.distanceMeters ?? double.infinity;
        double distB = b.distanceMeters ?? double.infinity;
        return distA.compareTo(distB);
      });
    } else if (selectedFilter == 'Toilet') {
      filtered = filtered.where((e) => e.hasToilet).toList();
    } else if (selectedFilter == 'Musholla') {
      filtered = filtered.where((e) => e.hasMusholla).toList();
    }

    // Search Logic
    String query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.name.toLowerCase().contains(query) ||
               e.address.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          },
        ),
        title: const Text(
          'SPBU',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: Icon(Icons.tune, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // FILTER CHIPS (Update 'Rating' ke 'Terdekat')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildFilterChip('Terdekat')), // Ganti Rating jadi Terdekat
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Buka')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Toilet')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Musholla')),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // LIST VIEW
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allSpbuList.isEmpty
                    ? const Center(child: Text("Data Kosong"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: getFilteredList().length,
                        itemBuilder: (context, index) {
                          final spbu = getFilteredList()[index];
                          return SPBUCard(spbu: spbu);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SPBUCard extends StatelessWidget {
  final SPBUModel spbu;

  const SPBUCard({Key? key, required this.spbu}) : super(key: key);

  Future<void> _openMapUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _openMapUrl(spbu.address);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 140), 
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Image.network(
                  spbu.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),

            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NAMA & STATUS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Expanded(
                          child: Text(
                            spbu.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 6),
                          decoration: BoxDecoration(
                            color: spbu.isCurrentlyOpen
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            spbu.isCurrentlyOpen ? 'Buka' : 'Tutup',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- UPDATE: Menampilkan Jarak dan Rating ---
                              Row(
                                children: [
                                  // Jarak
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    spbu.formattedDistance, // Menggunakan getter helper
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // Rating
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    spbu.rating.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Fasilitas Toilet
                              Row(
                                children: [
                                  Icon(Icons.wc,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Toilet',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    spbu.hasToilet
                                        ? 'Tersedia'
                                        : 'Tidak Tersedia',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: spbu.hasToilet
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Fasilitas Musholla
                              Row(
                                children: [
                                  Icon(Icons.mosque,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Musholla',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    spbu.hasMusholla
                                        ? 'Tersedia'
                                        : 'Tidak Tersedia',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: spbu.hasMusholla
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

// 9. UPDATE MODEL CLASS
class SPBUModel {
  final String name;
  final double rating;
  final bool hasToilet;
  final bool hasMusholla;
  final String imageUrl;
  final String address;
  final String openTime;
  final String closeTime;
  final double latitude;  // New
  final double longitude; // New
  
  // Field mutable untuk menyimpan jarak yang dihitung
  double? distanceMeters; 

  SPBUModel({
    required this.name,
    required this.rating,
    required this.hasToilet,
    required this.hasMusholla,
    required this.imageUrl,
    required this.address,
    required this.openTime,
    required this.closeTime,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  factory SPBUModel.fromJson(Map<String, dynamic> json) {
    return SPBUModel(
      name: json['name'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      hasToilet: json['has_toilet'] ?? false,
      hasMusholla: json['has_musholla'] ?? false,
      imageUrl: json['image_url'] ?? '',
      address: json['address'] ?? '',
      openTime: json['open_time'] ?? '00:00',
      closeTime: json['close_time'] ?? '00:00',
      // Pastikan field latitude/longitude ada di tabel Supabase kamu
      // Jika tipe datanya text, gunakan double.parse
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helper untuk format display jarak
  String get formattedDistance {
    if (distanceMeters == null) return '--';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toStringAsFixed(0)} m';
    } else {
      double km = distanceMeters! / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  bool get isCurrentlyOpen {
    try {
      final now = TimeOfDay.now();
      final open = _parseTime(openTime);
      final close = _parseTime(closeTime);

      if (open.hour == 0 && close.hour == 23 && close.minute == 59) {
        return true;
      }

      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = open.hour * 60 + open.minute;
      final closeMinutes = close.hour * 60 + close.minute;

      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } catch (e) {
      return false;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}