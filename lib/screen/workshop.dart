import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';
import 'package:uride/main.dart'; // supabase
import 'package:uride/routes/app_routes.dart';
import 'package:geolocator/geolocator.dart';

class BengkelListScreen extends StatefulWidget {
  const BengkelListScreen({Key? key}) : super(key: key);

  @override
  State<BengkelListScreen> createState() => _BengkelListScreenState();
}

class _BengkelListScreenState extends State<BengkelListScreen> {
  // 1. Ubah default filter menjadi 'Terdekat'
  String selectedFilter = 'Terdekat'; 
  List<Map<String, dynamic>> bengkelList = [];
  TextEditingController searchController = TextEditingController();
  
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    _initData();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _determinePosition();
    await fetchWorkshops();
  }

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
          userPosition = pos;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> fetchWorkshops() async {
    try {
      final response = await supabase.from('workshops').select();

      if (mounted) {
        setState(() {
          bengkelList = response.map<Map<String, dynamic>>((item) {
            
            // 2. Hitung jarak mentah (double) dan format string
            double? meters;
            String distanceString = '--';

            if (userPosition != null && item['latitude'] != null && item['longitude'] != null) {
               try {
                 final double latD = (item['latitude'] is num) ? item['latitude'].toDouble() : double.parse(item['latitude'].toString());
                 final double lngD = (item['longitude'] is num) ? item['longitude'].toDouble() : double.parse(item['longitude'].toString());
                 
                 meters = Geolocator.distanceBetween(
                    userPosition!.latitude,
                    userPosition!.longitude,
                    latD,
                    lngD,
                 );
                 distanceString = _formatDistance(meters);
               } catch (e) {
                 print("Error parsing latlng: $e");
               }
            }

            return {
              'id': item['id'],
              'name': item['bengkelname'],
              'is_open': item['is_open'],
              'distance_m': meters, // SIMPAN JARAK MENTAH (double) UNTUK SORTING
              'distance': distanceString, // Simpan String untuk UI
              'rating': item['rating'] ?? 0.0,
              'image': item["image"] ?? 'assets/images/workshop.png',
              'save': item['save'] ?? false,
              'services': item['services'] ?? [],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetch: $e');
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  List<Map<String, dynamic>> getFilteredList() {
    // Buat salinan list agar tidak mengubah list asli secara permanen saat sorting
    List<Map<String, dynamic>> filtered = List.from(bengkelList);

    // 3. Logika Sorting Berdasarkan Filter
    if (selectedFilter == 'Terdekat') {
      // Sort berdasarkan distance_m (jarak meter)
      filtered.sort((a, b) {
        double distA = a['distance_m'] ?? double.infinity; // Jika null anggap sangat jauh
        double distB = b['distance_m'] ?? double.infinity;
        return distA.compareTo(distB); // Kecil ke Besar (Ascending)
      });
    } else if (selectedFilter == 'Favorit') {
      filtered = filtered.where((b) => b['save'] == true).toList();
    } else if (selectedFilter == 'Rating') {
      filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    } else if (selectedFilter == 'Buka') {
      filtered = filtered.where((b) => b['is_open'] == true).toList();
    }

    // Filter Search Text
    String query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((b) => b['name'].toString().toLowerCase().contains(query))
          .toList();
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
        title: const Text(
          'Bengkel',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // 4. Update UI Chip dari 'All' ke 'Terdekat'
                Expanded(child: _buildFilterChip('Terdekat')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Favorit')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Rating')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Buka')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bengkelList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: getFilteredList().length,
                    itemBuilder: (context, index) {
                      final data = getFilteredList()[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.workshopDetail,
                            arguments: {'workshopId': data['id']},
                          );
                        },
                        child: BengkelCard(data: data),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
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

class BengkelCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const BengkelCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80), 
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Image.network(
                data['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Image.asset('assets/images/workshop.png', fit: BoxFit.cover),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        decoration: BoxDecoration(
                          color: data['is_open'] == true
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['is_open'] == true ? 'Buka' : 'Tutup',
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
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        data['distance'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        data['rating'].toString(),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}