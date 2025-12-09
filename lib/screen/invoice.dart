import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uride/screen/workshop.dart';

class InvoiceScreen extends StatefulWidget {
  final int orderId; // ubah jadi int supaya sesuai tabel orders
  final String workshopName;
  final String workshopAddress;
  final String userAddress;
  final String vehicleType;
  final String requestType;
  final bool isOnLocation;
  final int price;

  const InvoiceScreen({
    Key? key,
    required this.orderId,
    required this.workshopName,
    required this.workshopAddress,
    required this.userAddress,
    required this.vehicleType,
    required this.requestType,
    this.isOnLocation = false,
    required this.price,
  }) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  String paymentStatus = 'pending';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentStatus();
  }

  Future<void> _fetchPaymentStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('paymentstatus')
          .eq('id', widget.orderId)
          .single();

      setState(() {
        paymentStatus = response['paymentstatus'] ?? 'pending';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil status pembayaran')),
      );
    }
  }

  Color getStatusColor() {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
      default:
        return Colors.orange;
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BengkelListScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const BengkelListScreen()),
                (route) => false,
              );
            },
          ),
          title: const Text(
            'Invoice',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _fetchPaymentStatus,
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildWorkshopCard(),
                    const SizedBox(height: 16),
                    _buildInvoiceInfo(),
                    const SizedBox(height: 16),
                    _buildCostSummary(),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWorkshopCard() {
    return Container(
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.workshopAddress,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice ID: ${widget.orderId}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTag(Icons.location_on, 'Lokasi', Colors.amber),
              const SizedBox(width: 8),
              _buildTag(
                widget.vehicleType.toLowerCase() == 'mobil'
                    ? Icons.directions_car
                    : Icons.motorcycle,
                widget.vehicleType,
                Colors.amber,
              ),
              const SizedBox(width: 8),
              _buildTag(Icons.circle, widget.requestType, _getRequestTypeColor()),
            ],
          ),
          if (widget.isOnLocation) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTag(Icons.construction, 'Servis di lokasi', Colors.blue),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status Pembayaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  paymentStatus.toUpperCase(),
                  style: TextStyle(color: getStatusColor(), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          const Text('Ringkasan Biaya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildCostRow('Biaya Panggilan', widget.price),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildCostRow('Total Biaya', widget.price, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, int amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, color: Colors.grey[700])),
        Text(
          'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          style: TextStyle(
              fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.black : Colors.grey[700]),
        ),
      ],
    );
  }
}
