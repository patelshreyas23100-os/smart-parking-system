import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../models/booking.dart';
import '../main_navigation.dart';

class DigitalReceiptScreen extends StatelessWidget {
  final Booking booking;
  const DigitalReceiptScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Digital Receipt'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigation()),
              (route) => false,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 80),
                  const SizedBox(height: 16),
                  const Text('Payment Successful', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Thank you for choosing Park Smart', style: TextStyle(color: AppColors.textSecondary)),
                  const Divider(height: 48),
                  
                  _buildReceiptRow('Booking ID', '#BP${booking.id.toString().padLeft(4, '0')}'),
                  _buildReceiptRow('Parking Slot', booking.slot?.slotNumber ?? 'N/A'),
                  _buildReceiptRow('Location', booking.slot?.location ?? 'General'),
                  _buildReceiptRow('Vehicle', booking.vehicle?.plateNumber ?? 'N/A'),
                  const Divider(height: 32),
                  
                  _buildReceiptRow('Start Time', dateFormat.format(booking.startTime)),
                  _buildReceiptRow('End Time', dateFormat.format(booking.endTime)),
                  _buildReceiptRow('Payment Method', booking.paymentMethod),
                  const Divider(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₹ ${booking.totalPrice.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Logic to download or share could go here
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt saved to downloads')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Download Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
