import 'package:flutter/material.dart';

class SearchResultPage extends StatelessWidget {
  final Map<String, dynamic>? arguments;

  const SearchResultPage({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = arguments ?? {};

    final query = args['query'] ?? '';
    final List bengkel = args['bengkel'] ?? [];
    final List spbu = args['spbu'] ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Column(
          children: [
            _buildHeader(context, query),

            const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: "Bengkel"),
                Tab(text: "SPBU"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildList(bengkel),
                  _buildList(spbu),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= HEADER =========================

  Widget _buildHeader(BuildContext context, String query) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD93D), Color(0xFFFF8400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(child: _buildSearchBar(context, query)),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            "Hasil untuk \"$query\"",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, String initialValue) {
    return InkWell(
      onTap: () {
        Navigator.pushReplacementNamed(context, '/search');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                initialValue,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= LIST =========================

  Widget _buildList(List data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada hasil ditemukan",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];

        final name = item['name'] ?? item['bengkelname'] ?? "Tanpa Nama";
        final rating = (item['rating'] ?? "4.5").toString();
        final distance = (item['distance'] ?? "--").toString();
        final status = item['status'] ?? "Buka";
        final image = item['image'] ?? "assets/images/workshop.png";

        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: _buildWorkshopCard(
            name: name,
            distance: distance,
            rating: rating,
            image: image,
            status: status,
          ),
        );
      },
    );
  }

  // ===================== CARD =============================

  Widget _buildWorkshopCard({
    required String name,
    required String distance,
    required String rating,
    required String image,
    required String status,
  }) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // NAME + DISTANCE + RATING
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff3d3d3d),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(distance),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(rating),
                        ],
                      ),
                    ],
                  ),

                  // STATUS BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      color: status == "Buka" ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white),
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
