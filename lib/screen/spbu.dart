import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';

class SPBUListScreen extends StatefulWidget {
  const SPBUListScreen({Key? key}) : super(key: key);

  @override
  State<SPBUListScreen> createState() => _SPBUListScreenState();
}

class _SPBUListScreenState extends State<SPBUListScreen> {
  String selectedFilter = 'Buka';
  String searchQuery = '';

  Future<List<SPBUModel>> fetchSPBU(String filter) async {
    final response = await Supabase.instance.client
        .from('spbu')
        .select()
        .order('name', ascending: true);

    List<SPBUModel> list =
        response.map<SPBUModel>((data) => SPBUModel.fromJson(data)).toList();

    // Search filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.address.toLowerCase().contains(q);
      }).toList();
    }

    if (filter == 'Buka') {
      list = list.where((e) => e.isCurrentlyOpen).toList();
    } else if (filter == 'Rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (filter == 'Toilet') {
      list = list.where((e) => e.hasToilet).toList();
    } else if (filter == 'Musholla') {
      list = list.where((e) => e.hasMusholla).toList();
    }

    return list;
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
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
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
                Expanded(child: _buildFilterChip('Buka')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Rating')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Toilet')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('Musholla')),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<SPBUModel>>(
              future: fetchSPBU(selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Gagal memuat data',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                final spbuList = snapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: spbuList.length,
                  itemBuilder: (context, index) {
                    return SPBUCard(spbu: spbuList[index]);
                  },
                );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// CARD
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: Image.asset(
                  spbu.imageUrl,
                  fit: BoxFit.cover,
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
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME AND STATUS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            spbu.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

                    // RATING, FACILITIES
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
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

// MODEL
class SPBUModel {
  final String name;
  final double rating;
  final bool hasToilet;
  final bool hasMusholla;
  final String imageUrl;
  final String address;
  final String openTime;
  final String closeTime;

  SPBUModel({
    required this.name,
    required this.rating,
    required this.hasToilet,
    required this.hasMusholla,
    required this.imageUrl,
    required this.address,
    required this.openTime,
    required this.closeTime,
  });

  factory SPBUModel.fromJson(Map<String, dynamic> json) {
    return SPBUModel(
      name: json['name'],
      rating: (json['rating'] as num).toDouble(),
      hasToilet: json['has_toilet'],
      hasMusholla: json['has_musholla'],
      imageUrl: json['image_url'],
      address: json['address'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }

  bool get isCurrentlyOpen {
    final now = TimeOfDay.now();
    final open = _parseTime(openTime);
    final close = _parseTime(closeTime);

    // 24 JAM
    if (open.hour == 0 && close.hour == 23 && close.minute == 59) {
      return true;
    }

    final nowMinutes = now.hour * 60 + now.minute;
    final openMinutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;

    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
