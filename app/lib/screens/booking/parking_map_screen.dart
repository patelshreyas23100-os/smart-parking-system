import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'vehicle_type_selection_screen.dart';

class AreaLocation {
  final String name;
  final LatLng position;
  final String spots;
  final IconData icon;

  AreaLocation(this.name, this.position, this.spots, this.icon);
}

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  final List<AreaLocation> locations = [
    AreaLocation('Mall', const LatLng(23.0396, 72.5310), '12 Spots', Icons.shopping_bag),
    AreaLocation('Office', const LatLng(23.0225, 72.5714), '8 Spots', Icons.work),
    AreaLocation('Theater', const LatLng(23.0270, 72.5057), '5 Spots', Icons.movie),
    AreaLocation('Hotel', const LatLng(23.0416, 72.5739), '10 Spots', Icons.hotel),
    AreaLocation('Market', const LatLng(23.0257, 72.5645), '15 Spots', Icons.store),
    AreaLocation('Airport', const LatLng(23.0772, 72.6347), '20 Spots', Icons.flight),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location on Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(23.0225, 72.5714),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_smart_park',
          ),
          MarkerLayer(
            markers: locations.map((loc) => Marker(
              point: loc.position,
              width: 80,
              height: 80,
              child: GestureDetector(
                onTap: () => _showLocationDetails(loc),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                        ],
                      ),
                      child: Icon(loc.icon, color: Colors.white, size: 24),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showLocationDetails(AreaLocation loc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(loc.icon, size: 40, color: AppColors.primary),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text(loc.spots, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                const Text('AVAILABLE', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<BookingProvider>(context, listen: false).setLocation(loc.name);
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleTypeSelectionScreen()),
                );
              },
              child: const Text('SELECT THIS LOCATION'),
            ),
          ],
        ),
      ),
    );
  }
}
