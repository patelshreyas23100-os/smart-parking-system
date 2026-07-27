import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_service.dart';
import '../../models/parking_slot.dart';
import '../../utils/constants.dart';
import 'time_selection_screen.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<ParkingSlot>> _slotsFuture;

  @override
  void initState() {
    super.initState();
    final booking = Provider.of<BookingProvider>(context, listen: false);
    _slotsFuture = _apiService.getSlots(
      type: booking.selectedVehicleType,
      location: booking.selectedLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Parking')),
      body: FutureBuilder<List<ParkingSlot>>(
        future: _slotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          final slots = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Available', AppColors.primaryLight, AppColors.primary),
                    const SizedBox(width: 20),
                    _buildLegendItem('Booked', Colors.grey[200]!, Colors.grey),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return _buildSlotItem(context, slot);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String text, Color bgColor, Color textColor) {
    return Row(
      children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSlotItem(BuildContext context, ParkingSlot slot) {
    final booking = Provider.of<BookingProvider>(context, listen: false);
    final isAvailable = slot.is_available;

    return InkWell(
      onTap: isAvailable ? () {
        booking.setSlot(slot);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeSelectionScreen()));
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.primaryLight : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isAvailable ? AppColors.primary : Colors.grey[300]!, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slot.slotNumber, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isAvailable ? AppColors.primary : Colors.grey)),
              const SizedBox(height: 4),
              if (!isAvailable) const Text('Booked', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
