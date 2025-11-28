import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

    // ambil user id - hardcode
    final userId = 'ac2240e5-5bf9-4314-8892-0f925639bde8';

    final response = await supabase
        .from('orders')
        .select('*, workshops(*), vehicles(*)')
        .eq('userid', userId) // filter sesuai user login
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
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _header(),
                    const SizedBox(height: 20),
                    _searchBar(),
                    const SizedBox(height: 25),

                    // group by date 
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
      final vehicle = o['vehicles'];

      final bengkelName =
          workshop?['bengkelname']?.toString().toLowerCase() ?? "";
      final orderType = o['ordertype']?.toString().toLowerCase() ?? "";
      final vehicleType =
          vehicle?['vehicletype']?.toString().toLowerCase() ?? "";

      // format tanggal: "15 Januari 2025"
      final formattedDate = formatDate(o['orderdate'].toString()).toLowerCase();

      return bengkelName.contains(keyword) ||
          orderType.contains(keyword) ||
          vehicleType.contains(keyword) ||
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
        final vehicle = o['vehicles'];
        String rawLoc = workshop?['bengkellocation']?.toString() ?? "0,0";
        List<String> loc = rawLoc.split(",");

        double lat = double.tryParse(loc[0].trim()) ?? 0;
        double lng = double.tryParse(loc.length > 1 ? loc[1].trim() : "0") ?? 0;

        widgets.add(
          _orderCard(
            date: date,
            statusOngoing: ongoing,
            statusCancelled: cancelled,
            title: cleanText(workshop?['bengkelname'] ?? "-"),
            address: cleanText(workshop?['address'] ?? "-"),
            fullAddress: cleanText(workshop?['bengkellocation'] ?? "-"),
            typeVehicle: cleanText(vehicle?['vehicletype'] ?? "-"),
            typeCase: cleanText(o['ordertype'] ?? "-"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(
                    date: date,
                    statusOngoing: ongoing,
                    title: cleanText(workshop?['bengkelname'] ?? "-"),
                    address: cleanText(workshop?['address'] ?? "-"),
                    fullAddress:
                        workshop?['bengkellocation']?.toString() ?? "-",
                    typeVehicle: cleanText(vehicle?['vehicletype'] ?? "-"),
                    typeCase: cleanText(o['ordertype'] ?? "-"),
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
        style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          hintText: "Search...",
          hintStyle: GoogleFonts.poppins(
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
    required String typeVehicle,
    required String typeCase,
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
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    style: GoogleFonts.poppins(
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
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
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
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
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
                    style: GoogleFonts.poppins(fontSize: 12),
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
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              Text(
                "Siap-siap, bantuan segera tiba!",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _circleIcon("images/message.png"),
                  const SizedBox(width: 18),
                  _circleIcon("images/call.png"),
                ],
              ),
            ] else if (statusCancelled) ...[
              Text(
                "Pesanan ini telah dibatalkan.",
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.red),
              ),
            ] else ...[
              Text(
                "Pesanan anda telah terselesaikan.",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ]
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
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Image.asset(_getIconForTag(text), width: 15, height: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getIconForTag(String type) {
    switch (type.toLowerCase()) {
      case "motor":
        return "images/motor-default.png";
      case "normal":
        return "images/normal.png";
      case "emergency":
        return "images/emergency.png";
      case "derek kendaraan":
        return "images/derek.png";
      case "servis di lokasi":
        return "images/derek.png";
      case "mobil":
        return "images/mobil-default.png";
      case "peta":
        return "images/arrow.png";
      default:
        return "images/derek.png";
    }
  }

  Widget _circleIcon(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xffEAEAEA)),
      ),
      child: Image.asset(
        assetPath,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
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
      "Desember"
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
        .map((word) => word.isNotEmpty
            ? "${word[0].toUpperCase()}${word.substring(1)}"
            : "")
        .join(" ");
  }
}
