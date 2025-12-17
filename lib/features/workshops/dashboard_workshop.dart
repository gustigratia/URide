import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/features/profile/profile_page.dart';

class DashboardWorkshop extends StatefulWidget {
  const DashboardWorkshop({super.key});

  @override
  State<DashboardWorkshop> createState() => _DashboardWorkshopState();
}

class _DashboardWorkshopState extends State<DashboardWorkshop> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? workshop;
  List<dynamic> orderList = [];

  @override
  void initState() {
    super.initState();
    loadWorkshop();
  }

  // =============================================================
  // FETCH WORKSHOP BY USER ID
  // =============================================================
  Future<void> loadWorkshop() async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from("workshops")
        .select()
        .eq("userid", userId)
        .maybeSingle();

    workshop = data;

    setState(() {});

    loadOrders();
  }

  Future<void> loadOrders() async {
    if (workshop == null) return;

    final data = await supabase
        .from("orders")
        .select("""
      id,
      orderdate,
      addressdetail,
      ordertype,
      orderstatus,
      vehicletype,

      users:users!orders_userid_fkey(
        firstname,
        lastname
      )
    """)
        .eq("bengkelid", workshop!["id"])
        .order("orderdate", ascending: false);

    setState(() {
      orderList = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  if (workshop != null) _buildWorkshopHeader(),

                  const SizedBox(height: 20),

                  if (orderList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text("Belum ada pesanan"),
                      ),
                    )
                  else
                    Column(
                      children: orderList.map((o) {
                        final user = o["users"];
                        final vehicleType = o["vehicletype"];

                        return Column(
                          children: [
                            OrderCard(
                              orderId: "ORDER${o["id"]}",
                              name: "${user["firstname"]} ${user["lastname"]}",
                              date: _formatDate(o["orderdate"]),
                              address: o["addressdetail"] ?? "-",
                              vehicleType: vehicleType ?? "-",
                              orderType: o["ordertype"] ?? "-",
                              status: o["orderstatus"] == "ongoing"
                                  ? "On going"
                                  : o["orderstatus"] == "completed"
                                  ? "Completed"
                                  : o["orderstatus"] == "cancelled"
                                  ? "Cancelled"
                                  : o["orderstatus"] ?? "-", 
                              statusColor: o["orderstatus"] == "ongoing"
                                  ? Colors.orange 
                                  : o["orderstatus"] == "completed"
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
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
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
            child: const Icon(Icons.arrow_back, size: 26, color: Colors.white),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Bengkel Saya",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Euclid",
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildWorkshopHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.network(
            workshop!["image"],
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.08),
                  Colors.black.withOpacity(1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workshop!["bengkelname"],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: "Euclid",
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        workshop!["address"],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontFamily: "Euclid",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // DATE FORMAT
  // =============================================================
  String _formatDate(String raw) {
    final date = DateTime.parse(raw);
    const bulan = [
      "",
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
    return "${date.day} ${bulan[date.month]} ${date.year}";
  }
}

class OrderCard extends StatelessWidget {
  final String orderId;
  final String name;
  final String date;
  final String address;
  final String vehicleType;
  final String orderType;
  final String status;
  final Color statusColor;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.name,
    required this.date,
    required this.address,
    required this.vehicleType,
    required this.orderType,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // 1. STATUS (PINDAH KE PALING ATAS)
          // ========================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontFamily: "Euclid",
                fontSize: 12, 
              ),
            ),
          ),

          const SizedBox(height: 12), // Jarak antara Status dan Nama

          // ========================================================
          // 2. ORDER ID & NAMA
          // ========================================================
          Text(
            "$orderId - $name",
            style: const TextStyle(
              fontSize: 16, // Sedikit diperbesar agar jelas
              fontWeight: FontWeight.w700,
              fontFamily: "Euclid",
            ),
          ),
          
          const SizedBox(height: 4),

          // ========================================================
          // 3. TANGGAL
          // ========================================================
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontFamily: "Euclid",
            ),
          ),

          const SizedBox(height: 12),

          // ========================================================
          // 4. ALAMAT
          // ========================================================
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.orange, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.black87,
                    fontFamily: "Euclid",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ========================================================
          // 5. TAGS (Tipe Kendaraan & Order Type)
          // ========================================================
          Row(
            children: [
              TagChip(
                icon: vehicleType.toLowerCase().contains("mobil")
                    ? Icons.directions_car_filled
                    : Icons.two_wheeler,
                label: vehicleType,
              ),
              const SizedBox(width: 10),
              OrderTypeChip(orderType: orderType),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderTypeChip extends StatelessWidget {
  final String orderType;

  const OrderTypeChip({super.key, required this.orderType});

  @override
  Widget build(BuildContext context) {
    Color dotColor;

    switch (orderType.toLowerCase()) {
      case "santai":
        dotColor = const Color(0xFF61D54D);
        break;
      case "normal":
        dotColor = const Color(0xFFFFC727);
        break;
      case "emergency":
        dotColor = const Color(0xFFFF3B30);
        break;
      default:
        dotColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            orderType,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: "Euclid",
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
//                          TAG CHIP
// ==================================================================

class TagChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const TagChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: "Euclid",
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
