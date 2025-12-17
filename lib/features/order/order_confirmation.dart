import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uride/core/services/midtrans_service.dart';
import 'package:uride/features/order/invoice.dart';

class KonfirmasiAjuanScreen extends StatefulWidget {
  final int workshopId;
  final String workshopName;
  final String workshopAddress;
  final String userAddress;
  final String vehicleType;
  final String requestType;
  final bool isOnLocation;
  final int price;

  const KonfirmasiAjuanScreen({
    Key? key,
    required this.workshopId,
    required this.workshopName,
    required this.workshopAddress,
    required this.userAddress,
    required this.vehicleType,
    required this.requestType,
    this.isOnLocation = false,
    required this.price, // pastikan diterima di constructor
  }) : super(key: key);

  @override
  State<KonfirmasiAjuanScreen> createState() => _KonfirmasiAjuanScreenState();
}

class _KonfirmasiAjuanScreenState extends State<KonfirmasiAjuanScreen> {
  String selectedPayment = 'cash'; 
  
  int get travelFee => widget.price;

  int get totalFee =>  travelFee;

  IconData _getVehicleIcon() {
    switch (widget.vehicleType.toLowerCase()) {
      case 'motor':
        return Icons.motorcycle;
      case 'mobil':
        return Icons.directions_car;
      default:
        return Icons.directions_bike;
    }
  }

  Color _getRequestTypeColor() {
    switch (widget.requestType.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'santai':
        return Colors.green;
      default:
        return Colors.amber;
    }
  }

  Future<int?> submitToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      final response = await Supabase.instance.client
          .from('orders')
          .insert({
            'userid': user?.id,
            'bengkelid': widget.workshopId,
            'addressdetail': widget.userAddress,
            'vehicletype': widget.vehicleType,
            'ordertype': widget.requestType,
            'paymentmethod': selectedPayment,
            'price': totalFee,
            'orderdate': DateTime.now().toIso8601String(),
            'paymentstatus': 'pending',
            'orderstatus': 'ongoing', // Penambahan value default ongoing
          })
          .select('id') // ambil ID yang baru dibuat
          .single(); // ambil satu record

      final orderId = response['id'] as int;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajuan berhasil dikirim"),
          backgroundColor: Colors.green,
        ),
      );

      return orderId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengirim ajuan: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Konfirmasi Ajuan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // WORKSHOP INFO CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workshopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.workshopAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AJUAN ANDA
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajuan Anda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Anda',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.userAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8.0,    // Jarak horizontal otomatis antar elemen
                    runSpacing: 8.0, // Jarak vertikal otomatis jika elemen turun ke baris baru
                    children: [
                      _buildTag(
                        icon: _getVehicleIcon(),
                        label: widget.vehicleType,
                        color: Colors.amber,
                      ),
                      
                      // SizedBox(width: 8) dihapus karena sudah digantikan oleh 'spacing'
                      
                      _buildTag(
                        icon: Icons.circle,
                        label: widget.requestType,
                        color: _getRequestTypeColor(),
                      ),

                      if (widget.isOnLocation) 
                        _buildTag(
                          icon: Icons.construction,
                          label: 'Servis di lokasi',
                          color: Colors.amber,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Ubah ajuan'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // BIAYA
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Biaya',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _buildCostRow('Biaya Panggilan', travelFee), // pakai widget.price
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildCostRow('Total Biaya', totalFee, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PAYMENT
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption('cash', 'Cash', '💳'),
                  const SizedBox(height: 8),
                  _buildPaymentOption('transfer', 'Transfer', '💳'),
                ],
              ),
            ),

            const SizedBox(height: 130),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Biaya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Rp ${totalFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) throw 'User belum login';

                // CASH
                if (selectedPayment == 'cash') {
                  final response = await Supabase.instance.client
                      .from('orders')
                      .insert({
                        'userid': user.id,
                        'bengkelid': widget.workshopId,
                        'addressdetail': widget.userAddress,
                        'vehicletype': widget.vehicleType,
                        'ordertype': widget.requestType,
                        'paymentmethod': 'cash',
                        'price': totalFee,
                        'orderdate': DateTime.now().toIso8601String(),
                        'paymentstatus': 'paid',
                        'orderstatus': 'ongoing', // Penambahan value default ongoing
                      })
                      .select('id')
                      .single();

                  final orderId = response['id'] as int;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceScreen(
                        orderId: orderId,
                        workshopName: widget.workshopName,
                        workshopAddress: widget.workshopAddress,
                        userAddress: widget.userAddress,
                        vehicleType: widget.vehicleType,
                        requestType: widget.requestType,
                        isOnLocation: widget.isOnLocation,
                        price: totalFee,
                      ),
                    ),
                  );
                  return;
                }

                // TRANSFER
                final orderId = await submitToSupabase(); // status pending
                if (orderId == null) return;

                final redirectUrl = await createMidtransTransaction(totalFee, orderId);

                // Buka Midtrans
                if (await canLaunchUrl(Uri.parse(redirectUrl))) {
                  await launchUrl(
                    Uri.parse(redirectUrl),
                    mode: LaunchMode.externalApplication,
                  );
                }

                // Setelah membuka Midtrans, tetap redirect ke invoice
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoiceScreen(
                      orderId: orderId,
                      workshopName: widget.workshopName,
                      workshopAddress: widget.workshopAddress,
                      userAddress: widget.userAddress,
                      vehicleType: widget.vehicleType,
                      requestType: widget.requestType,
                      isOnLocation: widget.isOnLocation,
                      price: totalFee,
                    ),
                  ),
                );

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terjadi kesalahan: $e')),
                );
              }
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'Bayar Sekarang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey[400]!),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 16, color: color),
        if (icon != null) const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildCostRow(String label, int amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          amount.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String label, String emoji) {
    final isSelected = selectedPayment == value;
    return InkWell(
      onTap: () {
        setState(() {
          selectedPayment = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.grey[300]!,
                  width: 2,
                ),
                color: isSelected ? Colors.amber : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}