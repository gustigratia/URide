import 'package:flutter/material.dart';
import 'package:uride/widgets/bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Future<Map<String, List<Map<String, dynamic>>>> searchFromDatabase(String keyword) async {
    final supabase = Supabase.instance.client;

    if (keyword.trim().isEmpty) {
      return {
        'bengkel': [],
        'spbu': [],
      };
    }

    // QUERY TABLE BENGKEL
    final bengkelResult = await supabase
        .from('workshops')
        .select()
        .ilike('bengkelname', '%$keyword%');

    // QUERY TABLE SPBU
    final spbuResult = await supabase
        .from('spbu')
        .select()
        .ilike('name', '%$keyword%');

    // Return dipisah untuk tab view
    return {
      'bengkel': bengkelResult
          .map((d) => {...d, 'type': 'bengkel'})
          .toList(),

      'spbu': spbuResult
          .map((d) => {...d, 'type': 'spbu'})
          .toList(),
    };
  }



  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> history = [
    "Car washh",
  ];
  final List<String> suggestions = [
    "Car wash",
    "Brake service",
    "Battery check",
  ];

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
        onTap: (index) {
          // print("Tapped: $index");
        },
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
                          const Icon(Icons.access_time, size: 22, color: Colors.black54),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 18,  // Bigger text
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => setState(() => history.remove(item)),
                            child: const Icon(Icons.close, size: 22, color: Colors.black54),
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
                          const Icon(Icons.search, size: 22, color: Colors.black54),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 18,   // sama kayak history
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () => setState(() => suggestions.remove(item)),
                            child: const Icon(Icons.close, size: 22, color: Colors.black54),
                          ) // biar align sama close-button history
                        ],
                      ),
                    ),
                  );
                }).toList()
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔙 Back button + search bar
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

              Expanded(child: _buildSearchBar()),
            ],
          ),
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

          // FIX: ubah jadi TextField agar bisa input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (value) async {
                print("VALUE: $value");

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
            )
          ),
        ],
      ),
    );
  }
}
