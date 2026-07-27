import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'qr_payment_screen.dart';
import 'payment_success_screen.dart';

class UPIPaymentScreen extends StatefulWidget {
  const UPIPaymentScreen({super.key});

  @override
  State<UPIPaymentScreen> createState() => _UPIPaymentScreenState();
}

class _UPIPaymentScreenState extends State<UPIPaymentScreen> {
  final _upiIdController = TextEditingController();
  String _selectedApp = 'GPay';
  bool _showUpiInput = false;

  Future<void> _showConfirmationDialog(String method, VoidCallback onConfirm) async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final total = (bookingProvider.endTime!.difference(bookingProvider.startTime!).inMinutes / 60.0) * 
                  bookingProvider.selectedSlot!.pricePerHour;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Proceed to pay using $method?'),
            const SizedBox(height: 16),
            Text('Total Amount: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String method) async {
    _showConfirmationDialog(method, () async {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.setPaymentMethod('UPI ($method)');
      
      // Simulate payment processing delay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context); // Close loader

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
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPI Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose UPI App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildUpiAppOption('GPay', 'Google Pay', Icons.account_balance_wallet),
            _buildUpiAppOption('PhonePe', 'PhonePe', Icons.account_balance),
            _buildUpiAppOption('Paytm', 'Paytm', Icons.payment),
            
            const Divider(height: 48),
            
            const Text('Other Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Enter UPI ID Option
            ListTile(
              leading: const Icon(Icons.alternate_email, color: AppColors.primary),
              title: const Text('Enter UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pay using any UPI ID'),
              trailing: Icon(_showUpiInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onTap: () => setState(() => _showUpiInput = !_showUpiInput),
            ),
            if (_showUpiInput) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _upiIdController,
                  decoration: InputDecoration(
                    hintText: 'user@upi',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: TextButton(
                      onPressed: () => _processPayment('ID: ${_upiIdController.text}'),
                      child: const Text('PAY'),
                    ),
                  ),
                ),
              ),
            ],
            
            // QR Code Option
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              title: const Text('Pay via QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Scan QR at parking spot'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QRPaymentScreen()));
              },
            ),

            const Divider(height: 32),

            // Auto Payment Option
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
              title: const Text('Auto Payment / Pay After Parking', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Direct payment after parking ends'),
              onTap: () => _processPayment('Auto-pay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppOption(String id, String name, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _processPayment(id),
      ),
    );
  }
}
