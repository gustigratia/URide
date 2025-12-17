import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CancelReasonPage extends StatefulWidget {
  final String orderId;

  const CancelReasonPage({super.key, required this.orderId});

  @override
  State<CancelReasonPage> createState() => _CancelReasonPageState();
}

class _CancelReasonPageState extends State<CancelReasonPage> {
  String? selectedReason;
  final TextEditingController otherController = TextEditingController();

  final List<String> reasons = [
    "Ajuan ganda",
    "Mekanik tidak ada respon",
    "Terlalu lama menunggu",
    "Lainnya",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Batalkan Pesanan",
          style: const TextStyle(
            fontFamily: "Euclid",
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pilih alasan pembatalan:",
              style: const TextStyle(
                fontFamily: "Euclid",
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // RADIO LIST
            ...reasons.map((reason) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => selectedReason = reason);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedReason == reason
                                  ? Colors.amber
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: selectedReason == reason
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reason,
                          style: const TextStyle(
                            fontFamily: "Euclid",
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),

            if (selectedReason == "Lainnya")
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: otherController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Tuliskan alasan pembatalan Anda...",
                    hintStyle: const TextStyle(
                      fontFamily: "Euclid",
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Kembali",
                        style: const TextStyle(
                          fontFamily: "Euclid",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _filledButton(
                    text: "Konfirmasi",
                    color: const Color(0xFFE3B007),
                    onTap: () {
                      _showCancelDialog(context, widget.orderId);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pesanan Berhasil Dibatalkan",
                  style: const TextStyle(
                    fontFamily: "Euclid",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBB0A21),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Pesanan Anda telah dibatalkan sesuai dengan permintaan.",
                  style: const TextStyle(fontFamily: "Euclid", fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF2C94C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final supabase = Supabase.instance.client;

                      final idInt = int.tryParse(orderId);

                      if (idInt != null) {
                        await supabase
                            .from('orders')
                            .update({'orderstatus': 'cancelled'})
                            .eq('id', idInt);
                      }

                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/history',
                        (route) => false,
                      );
                    },
                    child: Text(
                      "Kembali",
                      style: const TextStyle(
                        fontFamily: "Euclid",
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _filledButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 48,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: "Euclid",
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    ),
  );
}
