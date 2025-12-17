import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'cancelreason_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String title;
  final String address;
  final String fullAddress;
  final String typeCase;
  final String typeVehicle;
  final bool statusOngoing;
  final String? date;
  final String orderId;
  final double lat;
  final double lng;
  final int selectedRating;

  const OrderDetailScreen({
    super.key,
    required this.title,
    required this.address,
    required this.fullAddress,
    required this.typeCase,
    required this.typeVehicle,
    required this.statusOngoing,
    required this.lat,
    required this.lng,
    required this.orderId,
    this.date,
    this.selectedRating = 0,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String title = "";
  String address = "";
  String fullAddress = "";
  String typeCase = "";
  String typeVehicle = "";
  String orderId = "";
  double lat = 0;
  double lng = 0;
  String? date = "";
  int selectedRating = 0;
  String? workshopImageUrl;
  double? workshopLat;
  double? workshopLng;
  bool isLoadingMap = true;
  bool isLoadingImage = true;

  String orderStatus = "ongoing";

  @override
  void initState() {
    super.initState();
    title = widget.title;
    address = widget.address;
    fullAddress = widget.fullAddress;
    typeCase = widget.typeCase;
    typeVehicle = widget.typeVehicle;
    orderId = widget.orderId;
    lat = widget.lat;
    lng = widget.lng;
    date = widget.date;

    orderStatus = widget.statusOngoing ? "ongoing" : "completed";
    _fetchWorkshopImage();
    _fetchWorkshopLocation();
  }

  bool get isOngoing => orderStatus == "ongoing";
  bool get isCompleted => orderStatus == "completed";
  bool get isCancelled => orderStatus == "cancelled";



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Detail Pesanan",
                    style: const TextStyle(
                      fontFamily: "Euclid",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date != null ? formatDate(date!) : "-",
                          style: const TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isOngoing
                                ? const Color(0xffFAD97A)
                                : isCancelled
                                ? const Color(0xffBB0A21)
                                : const Color(0xff4CAF50),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOngoing
                                ? "Sedang Berlangsung"
                                : isCancelled
                                ? "Dibatalkan"
                                : "Selesai",
                            style: TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOngoing ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                            borderRadius: BorderRadius.circular(12),
                            child: isLoadingImage
                                ? Container(
                              width: 55,
                              height: 55,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                                : Image.network(
                              workshopImageUrl ??
                                  "https://via.placeholder.com/150", // fallback
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/workshop.png",
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cleanText(title),
                                  style: const TextStyle(
                                    fontFamily: "Euclid",
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  cleanText(address),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: "Euclid",
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cleanText(fullAddress),
                            style: const TextStyle(
                              fontFamily: "Euclid",
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip(cleanText(typeVehicle)),
                          const SizedBox(width: 10),
                          _chip(cleanText(typeCase)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isOngoing) ...[
                      Text(
                        "Mekanik sedang menuju lokasi Anda...",
                        style: const TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Siap-siap, bantuan segera tiba!",
                        style: TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                      ),
                    ] else if (isCancelled) ...[
                      Text(
                        "Pesanan anda telah dibatalkan.",
                        style: const TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 13,
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Pesanan anda telah terselesaikan.",
                        style: const TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 230,
                        child: isLoadingMap || workshopLat == null || workshopLng == null
                            ? const Center(
                          child: CircularProgressIndicator(),
                        )
                            : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(workshopLat!, workshopLng!),
                            zoom: 16,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId("workshop_loc"),
                              position: LatLng(workshopLat!, workshopLng!),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isCompleted
                                ? null
                                : _showCancelModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffD9534F),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Batalkan",
                              style: const TextStyle(
                                fontFamily: "Euclid",
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isOngoing
                                ? () => _showCompleteModal(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffF2C94C),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "Selesaikan",
                              style: const TextStyle(
                                fontFamily: "Euclid",
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchWorkshopImage() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('orders')
          .select('workshops(image)')
          .eq('id', orderId)
          .single();

      setState(() {
        workshopImageUrl = data['workshops']?['image'];
        isLoadingImage = false;
      });
    } catch (e) {
      debugPrint("Error fetch workshop image: $e");
      setState(() {
        isLoadingImage = false;
      });
    }
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
          "assets/images/motor-default.png",
          width: 15,
          height: 15,
          fit: BoxFit.contain,
        );

      case "mobil":
        return Image.asset(
          "assets/images/mobil-default.png",
          width: 15,
          height: 15,
          fit: BoxFit.contain,
        );

      case "santai":
        return Icon(
          Icons.circle,
          size: 10,
          color: const Color(0xFF61D54D),
        );

      case "normal":
        return Icon(
          Icons.circle,
          size: 10,
          color: const Color(0xFFFFC727),
        );

      case "emergency":
        return Icon(
          Icons.circle,
          size: 10,
          color: const Color(0xFFFF3B30),
        );

      default:
        return Image.asset("assets/images/arrow.png", width: 15, height: 15);
    }
  }
  void _showCompleteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Selesaikan Pesanan",
                style: const TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE3B007),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Apakah Anda yakin ingin menyelesaikan \npesanan Anda?",
                style: const TextStyle(fontFamily: "Euclid", fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Pastikan layanan benar-benar selesai. Dana akan diberikan kepada penyedia layanan.",
                style: const TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 13,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _outlinedButton(
                      text: "Kembali",
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filledButton(
                      text: "Selesaikan",
                      color: const Color(0xFFE3B007),
                      onTap: () async {
                        Navigator.pop(context);

                        final supabase = Supabase.instance.client;

                        await supabase
                            .from('orders')
                            .update({'orderstatus': 'completed'})
                            .eq('id', orderId);

                        setState(() {
                          orderStatus = "completed";
                        });
                        _showRatingModal();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Batalkan Pesanan",
                style: const TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBB0A21),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Apakah Anda yakin ingin membatalkan pesanan?",
                style: const TextStyle(fontFamily: "Euclid", fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Harap tinjau kebijakan pembatalan sebelum melanjutkan.",
                style: const TextStyle(
                  fontFamily: "Euclid",
                  fontSize: 13,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _outlinedButton(
                      text: "Kembali",
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _filledButton(
                      text: "Batalkan",
                      color: const Color(0xFFBB0A21),
                      onTap: () {
                        Navigator.pop(context);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CancelReasonPage(orderId: orderId),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _outlinedButton({required String text, required VoidCallback onTap}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: "Euclid",
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _filledButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: color,
      ),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: "Euclid",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pesanan Berhasil Diselesaikan",
                  style: const TextStyle(
                    fontFamily: "Euclid",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE3B007),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Pesanan Anda telah diselesaikan sesuai dengan permintaan. Terima kasih telah memilih layanan kami.",
                  style: const TextStyle(fontFamily: "Euclid", fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                _filledButton(
                  text: "Kembali",
                  color: const Color(0xFFE3B007),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchWorkshopLocation() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('orders')
          .select('workshops(latitude, longitude)')
          .eq('id', orderId)
          .single();

      setState(() {
        workshopLat = data['workshops']?['latitude']?.toDouble();
        workshopLng = data['workshops']?['longitude']?.toDouble();
        isLoadingMap = false;
      });
    } catch (e) {
      debugPrint("Error fetch workshop location: $e");
      isLoadingMap = false;
    }
  }

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Berikan Rating",
                    style: TextStyle(
                      fontFamily: "Euclid",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE3B007),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    "Seberapa puas Anda dengan layanan yang diberikan?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Euclid",
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedRating = starValue;
                          });
                        },
                        child: Icon(
                          selectedRating >= starValue
                              ? Icons.star
                              : Icons.star_border,
                          size: 36,
                          color: const Color(0xFFE3B007),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedRating == 0
                          ? null
                          : () async {
                              final supabase = Supabase.instance.client;

                              await supabase
                                  .from("orders")
                                  .update({"rating": selectedRating})
                                  .eq("id", orderId);

                              Navigator.pop(context);
                              _showSuccessDialog(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3B007),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Kirim",
                        style: TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
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

String formatDate(String rawDate) {
  final date = DateTime.parse(rawDate);

  const monthNames = [
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

  return "${date.day} ${monthNames[date.month]} ${date.year}";
}