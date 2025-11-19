import 'package:flutter/material.dart';

void main() {
  runApp(const SPBUApp());
}

class SPBUApp extends StatelessWidget {
  const SPBUApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPBU Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const SPBUListScreen(),
    );
  }
}

class SPBUListScreen extends StatefulWidget {
  const SPBUListScreen({Key? key}) : super(key: key);

  @override
  State<SPBUListScreen> createState() => _SPBUListScreenState();
}

class _SPBUListScreenState extends State<SPBUListScreen> {
  String selectedFilter = 'Terdekat';

  final List<SPBUModel> spbuList = [
    SPBUModel(
      name: 'SPBU Shell Arif Rahman Hakim',
      distance: 2.5,
      rating: 4.7,
      hasToilet: true,
      hasMusholla: true,
      isOpen: true,
      imageUrl: 'assets/shell_station.jpg',
    ),
    SPBUModel(
      name: 'SPBU Pertamina 502.214',
      distance: 4.2,
      rating: 4.7,
      hasToilet: true,
      hasMusholla: true,
      isOpen: false,
      imageUrl: 'assets/pertamina_station_1.jpg',
    ),
    SPBUModel(
      name: 'SPBU Pertamina 502.221',
      distance: 5.2,
      rating: 4.5,
      hasToilet: false,
      hasMusholla: false,
      isOpen: false,
      imageUrl: 'assets/pertamina_station_2.jpg',
    ),
  ];

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
          // Search Bar
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

          // Filter Chips
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

          // SPBU List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: spbuList.length,
              itemBuilder: (context, index) {
                return SPBUCard(spbu: spbuList[index]);
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
      margin: const EdgeInsets.only(bottom: 160),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[300],
              child: Image.asset(
                spbu.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.local_gas_station,
                      size: 60,
                      color: Colors.grey[500],
                    ),
                  );
                },
              ),
            ),
          ),

          // Content with margin top -40
          Positioned(
            top: 140, // 180 - 40 = 140
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
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 6,
                        ),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${spbu.distance} Km',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
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
                      Icon(Icons.wc, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Toilet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        spbu.hasToilet ? 'Tersedia' : 'Tidak Tersedia',
                        style: TextStyle(
                          fontSize: 13,
                          color: spbu.hasToilet ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.mosque, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Musholla',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        spbu.hasMusholla ? 'Tersedia' : 'Tidak Tersedia',
                        style: TextStyle(
                          fontSize: 13,
                          color: spbu.hasMusholla ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Tuju Lokasi',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
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
}