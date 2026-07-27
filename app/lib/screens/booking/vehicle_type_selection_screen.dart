import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'vehicle_list_screen.dart';

class VehicleTypeSelectionScreen extends StatelessWidget {
  const VehicleTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Vehicles')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTypeOption(context, 'Four-Wheeler', Icons.directions_car),
            const SizedBox(height: 20),
            _buildTypeOption(context, 'Two-Wheeler', Icons.motorcycle),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Provider.of<BookingProvider>(context, listen: false).setVehicleType(title);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleListScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Radio(value: true, groupValue: false, onChanged: (_) {}), // Visual placeholder
            const SizedBox(width: 12),
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
