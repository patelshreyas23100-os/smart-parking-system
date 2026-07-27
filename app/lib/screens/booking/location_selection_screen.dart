import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'vehicle_type_selection_screen.dart';
import 'parking_map_screen.dart';

class LocationSelectionScreen extends StatelessWidget {
  const LocationSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Location'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ParkingMapScreen()),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('VIEW MAP'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildLocationCard(context, 'Mall', Icons.shopping_bag, '12 Spots'),
          _buildLocationCard(context, 'Office', Icons.work, '8 Spots'),
          _buildLocationCard(context, 'Theater', Icons.movie, '5 Spots'),
          _buildLocationCard(context, 'Hotel', Icons.hotel, '10 Spots'),
          _buildLocationCard(context, 'Market', Icons.store, '15 Spots'),
          _buildLocationCard(context, 'Airport', Icons.flight, '20 Spots'),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String title, IconData icon, String subtitle) {
    return GestureDetector(
      onTap: () {
        Provider.of<BookingProvider>(context, listen: false).setLocation(title);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleTypeSelectionScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
