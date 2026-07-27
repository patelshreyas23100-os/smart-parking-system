import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'payment_screen.dart';

class CartSummaryScreen extends StatelessWidget {
  const CartSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final slot = booking.selectedSlot!;
    final vehicle = booking.selectedVehicle!;
    
    final duration = booking.endTime!.difference(booking.startTime!);
    final hours = duration.inMinutes / 60.0;
    final totalPrice = hours * slot.pricePerHour;

    return Scaffold(
      appBar: AppBar(title: const Text('View Cart')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(Icons.directions_car, 'Vehicle', '${vehicle.name} (${vehicle.plateNumber})'),
                  const Divider(height: 32),
                  _buildSummaryRow(Icons.location_on, 'Slot', '${slot.location} - ${slot.slotNumber}'),
                  const Divider(height: 32),
                  _buildSummaryRow(Icons.access_time, 'Duration', '${hours.toStringAsFixed(1)} Hr'),
                  const Divider(height: 32),
                  _buildSummaryRow(Icons.payments, 'Rate', 'Rs ${slot.pricePerHour}/hr'),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('Rs ${totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(120, 50),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
                    child: const Text('Pay Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
