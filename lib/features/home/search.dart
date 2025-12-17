import 'package:flutter/material.dart';
import 'package:uride/core/widgets/bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> history = ["Car washh"];
  final List<String> suggestions = ["Car wash", "Brake service", "Battery check"];

  Position? userPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
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

      userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {});
    } catch (e) {
      print("Location error: $e");
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

  Map<String, dynamic> _withDistance(Map<String, dynamic> item) {
    try {
      final lat = item['latitude'];
      final lng = item['longitude'];

      if (lat != null && lng != null && userPosition != null) {
        final double latD =
        (lat is num) ? lat.toDouble() : double.parse(lat.toString());
        final double lngD =
        (lng is num) ? lng.toDouble() : double.parse(lng.toString());

        final double meters = Geolocator.distanceBetween(
          userPosition!.latitude,
          userPosition!.longitude,
          latD,
          lngD,
        );

        item['distance_m'] = meters;
        item['distance'] = _formatDistance(meters);
      } else {
        item['distance_m'] = null;
        item['distance'] = '--';
      }
    } catch (e) {
      print("Distance calc error: $e");
      item['distance_m'] = null;
      item['distance'] = '--';
    }

    return item;
  }

  Future<Map<String, List<Map<String, dynamic>>>> searchFromDatabase(
      String keyword) async {
    final supabase = Supabase.instance.client;

    if (keyword.trim().isEmpty) {
      return {
        'bengkel': [],
        'spbu': [],
      };
    }

    final bengkelResult = await supabase
        .from('workshops')
        .select()
        .ilike('bengkelname', '%$keyword%');

    final spbuResult =
    await supabase.from('spbu').select().ilike('name', '%$keyword%');

    final List<Map<String, dynamic>> b =
    List<Map<String, dynamic>>.from(bengkelResult);
    final List<Map<String, dynamic>> s =
    List<Map<String, dynamic>>.from(spbuResult);

    final updatedB = b.map((e) => _withDistance({...e, 'type': 'bengkel'})).toList();
    final updatedS = s.map((e) => _withDistance({...e, 'type': 'spbu'})).toList();

    return {
      'bengkel': updatedB,
      'spbu': updatedS,
    };
  }

  void addHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      history.remove(query);
      history.insert(0, query);
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {},
      ),

      body: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ...history.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      onTap: () {
                        _controller.text = item;
                        _focusNode.requestFocus();
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 22, color: Colors.black54),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () =>
                                setState(() => history.remove(item)),
                            child: const Icon(Icons.close,
                                size: 22, color: Colors.black54),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),

                ...suggestions.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      onTap: () {
                        _controller.text = item;
                        _focusNode.requestFocus();

                        setState(() {
                          history.remove(item);
                          history.insert(0, item);
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 22, color: Colors.black54),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () =>
                                setState(() => suggestions.remove(item)),
                            child: const Icon(Icons.close,
                                size: 22, color: Colors.black54),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
      child: Row(
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
          Expanded(child: _buildSearchBar()),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
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
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (value) async {
                print("Searching: $value");

                final hasil = await searchFromDatabase(value);

                Navigator.pushNamed(
                  context,
                  '/search-result',
                  arguments: {
                    'query': value,
                    'bengkel': hasil['bengkel'],
                    'spbu': hasil['spbu'],
                  },
                );
              },
              decoration: const InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
