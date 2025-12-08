import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/routes/app_routes.dart';

class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({super.key});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  String selectedType = "motor";
  int selectedIndex = 0;

  List<dynamic> vehiclesMotor = [];
  List<dynamic> vehiclesMobil = [];

  @override
  void initState() {
    super.initState();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final motorData = await supabase
        .from('vehicles')
        .select()
        .eq("vehicletype", "motor")
        .eq("userid", user.id)
        .order("id", ascending: true);

    final mobilData = await supabase
        .from('vehicles')
        .select()
        .eq("vehicletype", "mobil")
        .eq("userid", user.id)
        .order("id", ascending: true);

    setState(() {
      vehiclesMotor = motorData;
      vehiclesMobil = mobilData;
    });
  }

  dynamic get currentVehicle {
    final list = selectedType == "motor" ? vehiclesMotor : vehiclesMobil;
    if (list.isEmpty) return null;
    return list[selectedIndex % list.length];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final list = selectedType == "motor" ? vehiclesMotor : vehiclesMobil;
    final hasVehicle = list.isNotEmpty;
    final v = currentVehicle;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Detail Kendaraan",
          style: TextStyle(
            fontFamily: 'Euclid',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // TAB MOTOR / MOBIL
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _vehicleTab(
                    title: "Motor",
                    icon: selectedType == "motor"
                        ? "images/motor(active).png"
                        : "images/motor(inactive).png",
                    active: selectedType == "motor",
                    onTap: () {
                      setState(() {
                        selectedType = "motor";
                        selectedIndex = 0;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  _vehicleTab(
                    title: "Mobil",
                    icon: selectedType == "mobil"
                        ? "images/mobil(active).png"
                        : "images/mobil(inactive).jpg",
                    active: selectedType == "mobil",
                    onTap: () {
                      setState(() {
                        selectedType = "mobil";
                        selectedIndex = 0;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // EMPTY STATE
              if (!hasVehicle) ...[
                const SizedBox(height: 40),
                const Text(
                  "Belum ada kendaraan",
                  style: TextStyle(
                    fontFamily: 'Euclid',
                    fontSize: 17,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                _fullButton(
                  icon: "images/edit.jpg",
                  title: "Tambah Kendaraan",
                  onTap: () {
                    Navigator.pushNamed(context, '/tambah-kendaraan');
                  },
                ),
                const SizedBox(height: 40),
              ],

              // DETAIL KENDARAAN
              if (hasVehicle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _navArrow(() => setState(() => selectedIndex--),
                        Icons.chevron_left),
                    Expanded(
                      child: Text(
                        v?['vehiclename'] ?? "-",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Euclid',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _navArrow(() => setState(() => selectedIndex++),
                        Icons.chevron_right),
                  ],
                ),

                const SizedBox(height: 15),

                SizedBox(
                  height: 200,
                  width: width * 0.75,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return SlideTransition(
                        position: slide,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      v != null && v['img'] != null && v['img'] != ""
                          ? "images/${v['img']}"
                          : "images/nmax.jpg",
                      key: ValueKey("img-${v?['id']}"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  v?['vehiclenumber'] ?? "-",
                  style: const TextStyle(
                    fontFamily: 'Euclid',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 15),

                // CARD PERJALANAN
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD233).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          "images/routing.jpg",
                          width: 22,
                          height: 22,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${v['kilometer']} Kilometer",
                            style: const TextStyle(
                              fontFamily: 'Euclid',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            "Total perjalanan",
                            style: TextStyle(
                              fontFamily: 'Euclid',
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // EDIT BUTTON — FIXED
                _fullButton(
                  icon: "images/edit.jpg",
                  title: "Edit Informasi Kendaraan",
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.editKendaraan,
                      arguments: {
                        "id": v?['id'], // kirim ID langsung
                        "index": selectedIndex,
                      },
                    );

                    if (result is Map && result["updated"] == true) {
                      await fetchVehicles();
                      setState(() {
                        selectedIndex = result["index"] ?? 0;
                      });
                    }
                  },
                ),

                const SizedBox(height: 10),
                _fullButton(
                  icon: "images/edit.jpg",
                  title: "Tambah Kendaraan",
                  onTap: () {
                    Navigator.pushNamed(context, '/tambah-kendaraan');
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _statusBox(
                        icon: "images/oli.jpg",
                        title: "${(v?['kilometer'] ?? 0) % 5000} Km",
                        subtitle: "Ganti Oli",
                        value: ((v?['kilometer'] ?? 0) % 5000) / 5000,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _statusBox(
                        icon: "images/wrench.jpg",
                        title: _nextServiceDate(v),
                        subtitle: "Servis Rutin",
                        value: _serviceProgress(v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _nextServiceDate(dynamic v) {
    if (v == null || v['lastservicedate'] == null) return "-";
    final raw = DateTime.tryParse(v['lastservicedate'].toString());
    if (raw == null) return "-";
    final next = raw.add(const Duration(days: 90));
    return "${next.day} ${_monthName(next.month)} ${next.year}";
  }

  double _serviceProgress(dynamic v) {
    if (v == null || v['lastservicedate'] == null) return 0;
    final raw = DateTime.tryParse(v['lastservicedate'].toString());
    if (raw == null) return 0;
    final elapsed = DateTime.now().difference(raw).inDays;
    return (elapsed / 90).clamp(0.0, 1.0);
  }

  String _monthName(int m) {
    const arr = [
      "",
      "Jan","Feb","Mar","Apr","Mei","Jun",
      "Jul","Agu","Sep","Okt","Nov","Des",
    ];
    return arr[m];
  }

  // WIDGETS
  Widget _navArrow(VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }

  Widget _vehicleTab({
    required String title,
    required String icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD233) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Image.asset(icon, width: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Euclid',
                fontSize: 16,
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullButton({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Image.asset(icon, width: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Euclid',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBox({
    required String icon,
    required String title,
    required String subtitle,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(icon, width: 32, height: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Euclid',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Euclid',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: value,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                value < 0.33
                    ? Colors.green
                    : value < 0.66
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
