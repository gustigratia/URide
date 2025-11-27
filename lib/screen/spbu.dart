import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SPBUListScreen extends StatefulWidget {
  const SPBUListScreen({Key? key}) : super(key: key);

  @override
  State<SPBUListScreen> createState() => _SPBUListScreenState();
}

class _SPBUListScreenState extends State<SPBUListScreen> {
  String selectedFilter = 'Terdekat';

  Future<List<SPBUModel>> fetchSPBU() async {
    final response = await Supabase.instance.client
        .from('spbu')
        .select()
        .order('distance', ascending: true);

    return response
        .map<SPBUModel>((data) => SPBUModel.fromJson(data))
        .toList();
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
          onPressed: () {},
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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
                _buildFilterChip('Terdekat'),
                const SizedBox(width: 8),
                _buildFilterChip('Rating'),
                const SizedBox(width: 8),
                _buildFilterChip('Musholla'),
                const SizedBox(width: 8),
                _buildFilterChip('Toilet'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<SPBUModel>>(
              future: fetchSPBU(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
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

class SPBUCard extends StatelessWidget {
  final SPBUModel spbu;

  const SPBUCard({Key? key, required this.spbu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                '${spbu.imageUrl}', // pakai imageUrl sesuai nama properti
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
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        decoration: BoxDecoration(
                          color: spbu.isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spbu.isOpen ? 'Buka' : 'Tutup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  '${spbu.distance} Km',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  spbu.rating.toString(),
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Icon(Icons.wc, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  'Toilet',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  spbu.hasToilet ? 'Tersedia' : 'Tidak Tersedia',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: spbu.hasToilet ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Icon(Icons.mosque, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  'Musholla',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  spbu.hasMusholla ? 'Tersedia' : 'Tidak Tersedia',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: spbu.hasMusholla ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      Container(
                        margin: const EdgeInsets.only(top: 36),
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Tuju Lokasi',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 16, color: Colors.orange),
                            ],
                          ),
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
    );
  }
}

class SPBUModel {
  final String name;
  final double distance;
  final double rating;
  final bool hasToilet;
  final bool hasMusholla;
  final bool isOpen;
  final String imageUrl;

  SPBUModel({
    required this.name,
    required this.distance,
    required this.rating,
    required this.hasToilet,
    required this.hasMusholla,
    required this.isOpen,
    required this.imageUrl,
  });

  factory SPBUModel.fromJson(Map<String, dynamic> json) {
    return SPBUModel(
      name: json['name'],
      distance: (json['distance'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      hasToilet: json['has_toilet'],
      hasMusholla: json['has_musholla'],
      isOpen: json['is_open'],
      imageUrl: json['image_url'],
    );
  }
}
