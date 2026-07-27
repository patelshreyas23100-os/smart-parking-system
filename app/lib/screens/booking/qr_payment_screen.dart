import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'payment_success_screen.dart';

class QRPaymentScreen extends StatefulWidget {
  const QRPaymentScreen({super.key});

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _startSimulatedScan();
  }

  Future<void> _startSimulatedScan() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isScanning = false);
      _confirmQRPayment();
    }
  }

  Future<void> _confirmQRPayment() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.setPaymentMethod('UPI (QR Scan)');
    
    try {
      final booking = await bookingProvider.confirmBooking();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => PaymentSuccessScreen(booking: booking)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            'Align QR Code within the frame',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isScanning)
                    const Icon(Icons.qr_code_scanner, size: 150, color: Colors.white24),
                  if (!_isScanning)
                    const Icon(Icons.check_circle, size: 100, color: AppColors.success),
                  
                  // Scanning animation line (simple simulation)
                  if (_isScanning)
                    const Positioned(
                      top: 50,
                      child: ScanningLine(),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              _isScanning ? 'Searching for QR code...' : 'QR Code Detected!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanningLine extends StatefulWidget {
  const ScanningLine({super.key});

  @override
  State<ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 2,
          margin: EdgeInsets.only(top: _controller.value * 150),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 4, spreadRadius: 2),
            ],
          ),
        );
      },
    );
  }
}
