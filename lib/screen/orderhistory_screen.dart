import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/widgets/bottom_nav.dart';
import 'orderdetail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController searchC = TextEditingController();
  List<dynamic> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    final userId = user.id;

    final response = await supabase
        .from('orders')
        .select('*, workshops(*)')
        .eq('userid', userId)
        .order('orderdate', ascending: false);

    setState(() {
      orders = response;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9F9),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),

      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _header(),
                    const SizedBox(height: 20),
                    _searchBar(),
                    const SizedBox(height: 25),

                    ..._buildOrderGroups(searchC.text),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildOrderGroups(String keyword) {
    keyword = keyword.toLowerCase();

    // filter order by search
    final filtered = orders.where((o) {
      final workshop = o['workshops'];
      final vehicle = o['vehicletype'];

      final bengkelName =
          workshop?['bengkelname']?.toString().toLowerCase() ?? "";
      final orderType = o['ordertype']?.toString().toLowerCase() ?? "";

      // format tanggal: "15 Januari 2025"
      final formattedDate = formatDate(o['orderdate'].toString()).toLowerCase();

      return bengkelName.contains(keyword) ||
          orderType.contains(keyword) ||
          formattedDate.contains(keyword);
    }).toList();

    // group by date
    Map<String, List<dynamic>> grouped = {};

    for (var order in filtered) {
      final date = order['orderdate'].toString().split('T')[0];
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(order);
    }

    List<Widget> widgets = [];

    grouped.forEach((date, list) {
      for (var o in list) {
        String status = o['orderstatus'] ?? "";
        bool ongoing = status == "ongoing";
        bool cancelled = status == "cancelled";

        final workshop = o['workshops'];

        double lat = double.tryParse(o?['latitude']?.toString() ?? "") ?? 0;
        double lng = double.tryParse(o?['longitude']?.toString() ?? "") ?? 0;

        widgets.add(
          _orderCard(
            date: date,
            statusOngoing: ongoing,
            statusCancelled: cancelled,
            title: cleanText(workshop?['bengkelname'] ?? "-"),
            address: cleanText(workshop?['address'] ?? "-"),
            fullAddress: cleanText(o?['addressdetail'] ?? "-"),
            typeCase: cleanText(o['ordertype'] ?? "-"),
            typeVehicle: cleanText(o?['vehicletype'] ?? "-"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    date: date,
                    statusOngoing: ongoing,
                    title: cleanText(workshop?['bengkelname'] ?? "-"),
                    address: cleanText(workshop?['address'] ?? "-"),
                    fullAddress: o['addressdetail'] ?? "-",
                    typeCase: cleanText(o['ordertype'] ?? "-"),
                    typeVehicle: cleanText(o?['vehicletype'] ?? "-"),
                    lat: lat,
                    lng: lng,
                    orderId: o['id'].toString(),
                  ),
                ),
              );
            },
          ),
        );

        widgets.add(const SizedBox(height: 10));
      }
    });

    return widgets;
  }

  Widget _header() {
    return Center(
      child: Text(
        "Riwayat Pesanan",
        style: const TextStyle(
          fontFamily: "Euclid",
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchC,
        onChanged: (value) {
          setState(() {}); // real-time update
        },
        style: const TextStyle(fontFamily: "Euclid"),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          hintText: "Search...",
          hintStyle: TextStyle(
            fontFamily: "Euclid",
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _orderCard({
    required String date,
    required bool statusOngoing,
    required bool statusCancelled,
    required String title,
    required String address,
    required String fullAddress,
    required String typeCase,
    required String typeVehicle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // date + status (card utama)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(date),
                  style: const TextStyle(
                    fontFamily: "Euclid",
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusOngoing
                        ? const Color(0xffFAD97A)
                        : statusCancelled
                        ? const Color(0xffE57373)
                        : const Color(0xff4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusOngoing
                        ? "Sedang Berlangsung"
                        : statusCancelled
                        ? "Dibatalkan"
                        : "Selesai",
                    style: const TextStyle(
                      fontFamily: "Euclid",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // foto bengkel + nama + alamat (card kecil)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      "images/bengkel.png",
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Alamat + Map
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fullAddress,
                    style: const TextStyle(fontFamily: "Euclid"),
                  ),
                ),
                const SizedBox(width: 8),
                _chip("Peta"),
              ],
            ),

            const SizedBox(height: 20),

            // chip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(typeVehicle),
                  const SizedBox(width: 10),
                  _chip(typeCase),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // status text
            if (statusOngoing) ...[
              Text(
                "Mekanik sedang menuju lokasi Anda...",
                style: const TextStyle(fontFamily: "Euclid", fontSize: 13),
              ),
              Text(
                "Siap-siap, bantuan segera tiba!",
                style: const TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ] else if (statusCancelled) ...[
              Text(
                "Pesanan ini telah dibatalkan.",
                style: const TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
            ] else ...[
              Text(
                "Pesanan anda telah terselesaikan.",
                style: const TextStyle(fontFamily: "Euclid", fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          getTagIcon(text), 
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: "Euclid",
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget getTagIcon(String type) {
    final t = type.toLowerCase();

    switch (t) {
      case "motor":
        return Image.asset(
          "images/motor-default.png",
          width: 15,
          height: 15,
          fit: BoxFit.contain,
        );

      case "mobil":
        return Image.asset(
          "images/mobil-default.png",
          width: 15,
          height: 15,
          fit: BoxFit.contain,
        );

      case "santai":
        return Icon(
          Icons.circle,
          size: 10,
          color: const Color(0xFF61D54D), // hijau
        );

      case "normal":
        return Icon(
          Icons.circle,
          size: 10,
          color: const Color(0xFFFFC727), // kuning
        );

      case "emergency":
        return Icon(
          Icons.circle,
          size: 10,
          color: const Color(0xFFFF3B30), // merah
        );

      // ===== DEFAULT =====
      default:
        return Image.asset("images/arrow.png", width: 15, height: 15);
    }
  }


  String formatDate(String rawDate) {
    final date = DateTime.parse(rawDate);

    const monthNames = [
      "", // dummy biar index mulai dari 1
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];

    final day = date.day;
    final month = monthNames[date.month];
    final year = date.year;

    return "$day $month $year";
  }

  String cleanText(String text) {
    if (text.isEmpty) return text;
    text = text.replaceAll("_", " ");
    text = text.toLowerCase();
    return text
        .split(" ")
        .map(
          (word) => word.isNotEmpty
              ? "${word[0].toUpperCase()}${word.substring(1)}"
              : "",
        )
        .join(" ");
  }
}
