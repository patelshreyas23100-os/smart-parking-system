import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'payment_success_screen.dart';
import 'upi_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Wallet';

  Future<void> _showConfirmationDialog(VoidCallback onConfirm) async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final total = (bookingProvider.endTime!.difference(bookingProvider.startTime!).inMinutes / 60.0) * 
                  bookingProvider.selectedSlot!.pricePerHour;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to book this slot?'),
            const SizedBox(height: 16),
            Text('Payment Method: $_selectedMethod', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedMethod == 'UPI') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UPIPaymentScreen()),
      );
      return;
    }

    _showConfirmationDialog(() async {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.setPaymentMethod(_selectedMethod);
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
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Option', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildPaymentOption(
              'UPI', 
              Icons.account_balance_wallet_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UPIPaymentScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('Wallet', Icons.wallet),
            const Spacer(),
            Consumer<BookingProvider>(
              builder: (context, booking, child) {
                return ElevatedButton(
                  onPressed: booking.isBooking ? null : _handlePayment,
                  child: booking.isBooking 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Confirm Payment'),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, {VoidCallback? onTap}) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: onTap ?? () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(method, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
