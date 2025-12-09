import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';
import 'package:uride/main.dart'; // supabase
import 'package:uride/routes/app_routes.dart';

class BengkelListScreen extends StatefulWidget {
  const BengkelListScreen({Key? key}) : super(key: key);

  @override
  State<BengkelListScreen> createState() => _BengkelListScreenState();
}

class _BengkelListScreenState extends State<BengkelListScreen> {
  String selectedFilter = 'All';
  List<Map<String, dynamic>> bengkelList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWorkshops();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchWorkshops() async {
    try {
      final response = await supabase.from('workshops').select();

      List<int> workshopIds = response.map<int>((w) => w['id'] as int).toList();

      final serviceResponse = await supabase
          .from('service')
          .select()
          .filter('workshop_id', 'in', '(${workshopIds.join(',')})');

      Map<int, List<String>> serviceMap = {};
      for (var s in serviceResponse) {
        int wid = s['workshop_id'];
        if (!serviceMap.containsKey(wid)) serviceMap[wid] = [];
        serviceMap[wid]!.add(s['name']);
      }

      setState(() {
        bengkelList = response.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['bengkelname'],
            'is_open': item['is_open'],
            'distance': '2 Km',
            'rating': item['rating'] ?? 0.0,
            'image':
                'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
            'save': item['save'] ?? false,
            'services': serviceMap[item['id']] ?? [],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetch: $e');
    }
  }

  List<Map<String, dynamic>> getFilteredList() {
    List<Map<String, dynamic>> filtered = bengkelList;

    if (selectedFilter == 'Favorit') {
      filtered = filtered.where((b) => b['save'] == true).toList();
    } else if (selectedFilter == 'Rating') {
      filtered = List.from(filtered);
      filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    } else if (selectedFilter == 'Buka') {
      filtered = filtered.where((b) => b['is_open'] == true).toList();
    }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const BengkelListScreen()),
              (route) => false, // hapus semua route sebelumnya agar langsung ke BengkelListScreen
            );
          },
        ),
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
                Expanded(child: _buildFilterChip('All')),
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
    List<String> services = List<String>.from(data['services'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 100),
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
                  const SizedBox(height: 12),

                  // Layanan
                  if (services.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: services.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
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
