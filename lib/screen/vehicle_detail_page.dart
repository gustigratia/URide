import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({super.key});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  String selectedType = "motor"; // motor | mobil
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

    final motorData = await supabase
        .from('vehicles')
        .select()
        .eq("vehicletype", "motor")
        .eq("userid", "ac2240e5-5bf9-4314-8892-0f925639bde8");

    final mobilData = await supabase
        .from('vehicles')
        .select()
        .eq("vehicletype", "mobil")
        .eq("userid", "ac2240e5-5bf9-4314-8892-0f925639bde8");

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
        top: false,
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              setState(() => selectedIndex++);
            } else if (details.primaryVelocity! > 0) {
              setState(() => selectedIndex--);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // TOP TAB
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _vehicleTab(
                      title: "Motor",
                      icon: selectedType == "motor"
                          ? "motor(active).png"
                          : "motor(inactive).png",
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
                          ? "mobil(active).png"
                          : "mobil(inactive).jpg",
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

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex--;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: const Icon(Icons.chevron_left, size: 22),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        v?['vehiclename'] ?? "-",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex++;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: const Icon(Icons.chevron_right, size: 22),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Image.asset(
                  "nmax.jpg",
                  width: width * 0.75,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 5),

                Text(
                  v?['vehiclenumber'] ?? "-",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),
                _fullButton(
                  icon: "edit.jpg",
                  title: "Edit Informasi Kendaraan",
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/edit-kendaraan',
                      arguments: {"id": v?['id'].toString()},
                    );

                    if (result == true) {
                      fetchVehicles();
                      setState(() {});
                    }
                  },
                ),

                const SizedBox(height: 10),

                _fullButton(icon: "edit.jpg", title: "Tambah Kendaraan"),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _statusBox(
                        icon: "oli.jpg",
                        title: "${v?['kilometer'] ?? 0} Km",
                        subtitle: "Ganti Oli",
                        barColor: const Color(0xFFFFD233),
                        value: ((v?['distance_oil'] ?? 0) / 5000)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _statusBox(
                        icon: "wrench.jpg",
                        title: "${v?['lastservicedate'] ?? 0} Hari Lagi",
                        subtitle: "Servis Rutin",
                        barColor: const Color(0xFFE53935),
                        value: ((v?['service_percent'] ?? 0) / 100)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Rincian",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                _infoCard(v),

                const SizedBox(height: 20),

                _oilCard(context, v),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // COMPONENTS
  // =======================================================================

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
    VoidCallback? onTap,
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
    required Color barColor,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(icon, width: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: value,
              backgroundColor: Colors.grey.shade200,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(v) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Informasi Kendaraan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Image.asset("odometer.jpg", width: 28),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${v?['kilometer_total'] ?? 0} Kilometer",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    "Total perjalanan",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Image.asset("clock.jpg", width: 28),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${v?['total_minutes'] ?? 0} menit",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    "Waktu berkendara",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageIcon(AssetImage("routing.jpg"), size: 18),
                SizedBox(width: 8),
                Text(
                  "Log Perjalanan",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _oilCard(BuildContext context, v) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Oli Mesin Kendaraan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "${v?['kilometer_last_oil'] ?? 0} Kilometer",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            "Terakhir ganti oli",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          Text(
            "${v?['distance_oil'] ?? 0}/${v?['kilometer_oil_target'] ?? 5000} Kilometer",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            "Ganti oli",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/atur-jadwal'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ImageIcon(AssetImage("calender.jpg"), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Atur Jadwal",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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