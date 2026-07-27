import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import '../../models/vehicle.dart';
import '../../utils/constants.dart';
import 'slot_selection_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _apiService.getMyVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Specific Vehicle')),
      body: FutureBuilder<List<Vehicle>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          final vehicles = snapshot.data!.where((v) => v.type == booking.selectedVehicleType).toList();

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No vehicles found for this type.'),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Add Vehicle in Profile')),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.directions_car, color: AppColors.primary)),
                  title: Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(vehicle.plateNumber),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    booking.setVehicle(vehicle);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SlotSelectionScreen()));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
