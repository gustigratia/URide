// lib/screens/payment_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'orderhistory_screen.dart';

// ==========================================================
//                  CONSTANTS & PAYMENT MODELS
// ==========================================================

const Color kPrimaryYellow = Color(0xFFFDC000);
const Color kDarkGrey = Color(0xFF4A4A4A);
const Color kLightBorder = Color(0xFFDCDCDC);
const double kLargeRadius = 30.0;
const Color kButtonDarkText = Color(0xFF6C6C6C);
const Color kOrangeGradient = Color(0xFFFF9100);
const double kIconSizePayment = 28.0;
const double kIconSizeGroup = 16.0;

class PaymentMethod {
  final String name;
  final String iconAsset;

  PaymentMethod(this.name, this.iconAsset);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

final List<PaymentMethod> visibleDefaultOptions = [
  PaymentMethod('Dana', 'assets/images/dana.png'),
  PaymentMethod('Gopay', 'assets/images/gopay.png'),
  PaymentMethod('Livin by Mandiri', 'assets/images/livin.png'),
];

final List<PaymentMethod> eWalletOptions = [
  PaymentMethod('Dana', 'assets/images/dana.png'),
  PaymentMethod('Gopay', 'assets/images/gopay.png'),
  PaymentMethod('ShopeePay', 'assets/images/shopeepay.png'),
  PaymentMethod('OVO', 'assets/images/ovo.png'),
];

final List<PaymentMethod> mobileBankingOptions = [
  PaymentMethod('BCA Mobile', 'assets/images/bca.png'),
  PaymentMethod('Livin by Mandiri', 'assets/images/livin.png'),
  PaymentMethod('BRIMo', 'assets/images/bri.png'),
];

final List<PaymentMethod> transferBankOptions = [
  PaymentMethod('BCA', 'assets/images/bca.png'),
  PaymentMethod('BRI', 'assets/images/bri.png'),
  PaymentMethod('BNI', 'assets/images/bni.png'),
  PaymentMethod('Mandiri', 'assets/images/mandiri.png'),
  PaymentMethod('CIMB Niaga', 'assets/images/cimb.png'),
];


// ==========================================================
//                    GLOBAL HELPER WIDGETS
// ==========================================================

Widget _buildSuccessButton({
  required String text,
  required Color color,
  required Color textColor,
  required VoidCallback onPressed,
  Color? borderColor,
}) {
  return Container(
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(kLargeRadius),
      border: Border.all(color: borderColor ?? Colors.transparent, width: 2),
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kLargeRadius),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Euclid',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: textColor,
        ),
      ),
    ),
  );
}

Widget _buildServiceButton(String assetPath, String label,
    {bool isPrimary = false}) {
  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? kPrimaryYellow.withOpacity(0.1)
            : kLightBorder.withOpacity(0.4),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Image.asset(
            assetPath,
            width: 14,
            height: 14,
            color: isPrimary ? kPrimaryYellow : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Euclid',
              fontSize: 11,
              color: isPrimary ? kPrimaryYellow : kDarkGrey,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCostRow(String label, int amount, {bool isTotal = false}) {
  String formattedAmount = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Euclid',
            fontSize: 14,
            color: isTotal ? Colors.black : kDarkGrey,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          formattedAmount,
          style: TextStyle(
            fontFamily: 'Euclid',
            fontSize: 14,
            color: isTotal ? Colors.black : kDarkGrey,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPaymentRow(PaymentMethod method, PaymentMethod? selectedMethod,
    Function(PaymentMethod?) onRadioChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        SizedBox(
          width: kIconSizePayment,
          height: kIconSizePayment,
          child: Image.asset(method.iconAsset, fit: BoxFit.contain),
        ),
        const SizedBox(width: 15),
        Text(
          method.name,
          style: const TextStyle(
            fontFamily: 'Euclid',
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Radio<PaymentMethod>(
          value: method,
          groupValue: selectedMethod,
          onChanged: onRadioChanged,
          activeColor: kPrimaryYellow,
        ),
      ],
    ),
  );
}


// ==========================================================
//                   SCREEN 3 – SUCCESS PAGE
// ==========================================================

class SuccessPage extends StatelessWidget {
  final VoidCallback onGoHome;
  final int newOrderId;

  const SuccessPage({
    super.key,
    required this.onGoHome,
    required this.newOrderId,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryYellow, kOrangeGradient],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.1),
            const Text(
              'Pemesanan',
              style: TextStyle(
                fontFamily: 'Euclid',
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Layanan Berhasil!',
              style: TextStyle(
                fontFamily: 'Euclid',
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 100,
              height: 100,
              child: Image.asset('assets/images/bawah.png'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Layanan Anda akan segera diproses.',
              style: TextStyle(fontFamily: 'Euclid', color: Colors.white),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildSuccessButton(
                    text: 'Lihat detail Ajuan',
                    color: Colors.white,
                    textColor: kButtonDarkText,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // newOrderId harus diteruskan (sudah tersedia di SuccessPage)
                          builder: (context) => OrderHistoryScreen(newOrderId: newOrderId), 
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildSuccessButton(
                    text: 'Kembali ke Beranda',
                    color: Colors.white,
                    textColor: kButtonDarkText,
                    onPressed: onGoHome,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }
}


// ==========================================================
//                   SCREEN 1 – PAYMENT PAGE
// ==========================================================

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderInput;

  const PaymentPage({super.key, required this.orderInput});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? selectedPaymentMethod;
  List<PaymentMethod> visibleDefaults = visibleDefaultOptions;

  Map<String, dynamic>? workshopData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = visibleDefaultOptions[0];
    _fetchWorkshopData();
  }

  Future<void> _fetchWorkshopData() async {
    final bengkelId = widget.orderInput['bengkelId'];

    try {
      final response = await Supabase.instance.client
          .from('workshops')
          .select()
          .eq('id', bengkelId)
          .single();

      setState(() {
        workshopData = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data bengkel: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _createOrderAndNavigate() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih metode pembayaran!',
            style: TextStyle(fontFamily: 'Euclid'),
          ),
        ),
      );
      return;
    }

    final newOrder = {
      'bengkelid': widget.orderInput['bengkelId'],
      'userid': widget.orderInput['userId'],
      'addressdetail': widget.orderInput['addressDetail'],
      'vehicletype': widget.orderInput['vehicleType'],
      'ordertype': widget.orderInput['orderType'],
      'price': widget.orderInput['price'],
      'paymentmethod': selectedPaymentMethod!.name,
      'orderstatus': 'Menunggu Konfirmasi',
      'orderdate': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final response = await Supabase.instance.client
          .from('orders')
          .insert(newOrder)
          .select('id')
          .single();

      final newOrderId = response['id'];

      _navigateToSuccessPage(newOrderId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(fontFamily: 'Euclid'),
          ),
        ),
      );
    }
  }

  void _navigateToSuccessPage(int orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessPage(
          newOrderId: orderId,
          onGoHome: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  Widget _buildShopInfo(Map<String, dynamic> w) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/bengkel.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              w['bengkelname'],
              style: const TextStyle(
                fontFamily: 'Euclid',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              w['address'],
              style: const TextStyle(
                fontFamily: 'Euclid',
                fontSize: 12,
                color: kDarkGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/lokasi.png',
                  width: 16, height: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.orderInput['addressDetail'],
                  style: const TextStyle(
                    fontFamily: 'Euclid',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              if (widget.orderInput['vehicleType'] == 'Mobil')
                _buildServiceButton(
                    'assets/images/mobil.png', 'Mobil'),
              if (widget.orderInput['orderType'] == 'Emergency')
                _buildServiceButton(
                    'assets/images/emergency.png', 'Emergency'),
              _buildServiceButton(
                  'assets/images/servis.png', 'Service di lokasi'),
              const Spacer(),
              _buildServiceButton(
                  'assets/images/peta.png', 'Peta',
                  isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Ringkasan Biaya',
          style: TextStyle(
            fontFamily: 'Euclid',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  void _navigateToSelectionPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentSelectionPage(initialSelection: selectedPaymentMethod),
      ),
    );

    if (result != null && result is PaymentMethod) {
      setState(() {
        selectedPaymentMethod = result;

        // tampilkan paling atas
        if (!visibleDefaultOptions.contains(result)) {
          visibleDefaults = [result, ...visibleDefaultOptions];
        }
      });
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: kLightBorder))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Biaya',
                  style: TextStyle(
                    fontFamily: 'Euclid',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Rp ${widget.orderInput['price']}",
                  style: const TextStyle(
                    fontFamily: 'Euclid',
                    color: kPrimaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _createOrderAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kLargeRadius),
                  ),
                ),
                child: const Text(
                  "Bayar Sekarang",
                  style: TextStyle(
                    fontFamily: 'Euclid',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryYellow),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMessage,
            style: const TextStyle(fontFamily: 'Euclid'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Layanan',
          style: TextStyle(
            fontFamily: 'Euclid',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kDarkGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShopInfo(workshopData!),
            const SizedBox(height: 20),

            const Text(
              "Pesanan Anda",
              style: TextStyle(
                fontFamily: 'Euclid',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            _buildOrderDetails(),
            const SizedBox(height: 20),

            _buildCostSummary(),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Metode Pembayaran",
                  style: TextStyle(
                    fontFamily: 'Euclid',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToSelectionPage,
                  child: const Row(
                    children: [
                      Text(
                        'Pilih Metode Pembayaran',
                        style: TextStyle(
                          fontFamily: 'Euclid',
                          color: kButtonDarkText,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.chevron_right, color: kButtonDarkText),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: kLightBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: visibleDefaults
                    .map(
                      (method) => _buildPaymentRow(
                        method,
                        selectedPaymentMethod,
                        (value) {
                          setState(() {
                            selectedPaymentMethod = value;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}


// ==========================================================
//             SCREEN 2 – PAYMENT SELECTION PAGE
// ==========================================================

class PaymentSelectionPage extends StatefulWidget {
  final PaymentMethod? initialSelection;

  const PaymentSelectionPage({super.key, this.initialSelection});

  @override
  State<PaymentSelectionPage> createState() => _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends State<PaymentSelectionPage> {
  PaymentMethod? selectedMethod;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.initialSelection;
  }

  Widget _buildMethodGroup({
    required String title,
    required List<PaymentMethod> methods,
    required String iconAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(iconAsset, width: 16, height: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Euclid',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...methods.map(
            (method) => _buildPaymentRow(
              method,
              selectedMethod,
              (value) {
                setState(() {
                  selectedMethod = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kLightBorder)),
        color: Colors.white,
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedMethod),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kLargeRadius),
              ),
            ),
            child: const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontFamily: 'Euclid',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(
            fontFamily: 'Euclid',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kDarkGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, selectedMethod),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMethodGroup(
              title: "E-Wallet",
              methods: eWalletOptions,
              iconAsset: "assets/images/e-wallet.png",
            ),
            const Divider(height: 1),
            _buildMethodGroup(
              title: "Mobile Banking",
              methods: mobileBankingOptions,
              iconAsset: "assets/images/bank.png",
            ),
            const Divider(height: 1),
            _buildMethodGroup(
              title: "Transfer Bank",
              methods: transferBankOptions,
              iconAsset: "assets/images/bank.png",
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSelectionBottomBar(),
    );
  }
}