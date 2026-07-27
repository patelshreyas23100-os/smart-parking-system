import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../models/parking_slot.dart';
import 'booking_details_screen.dart';

class SelectSlotScreen extends StatefulWidget {
  final String vehicleType;
  final int? locationId;
  final String? locationName;

  const SelectSlotScreen({super.key, required this.vehicleType, this.locationId, this.locationName});

  @override
  State<SelectSlotScreen> createState() => _SelectSlotScreenState();
}

class _SelectSlotScreenState extends State<SelectSlotScreen> {
  final _apiService = ApiService();
  List<ParkingSlot> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      List<ParkingSlot> slots;
      if (widget.locationId != null) {
        slots = await _apiService.getSlotsByLocationId(widget.locationId!, type: widget.vehicleType);
      } else {
        slots = await _apiService.getSlots(widget.vehicleType);
      }
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.locationName ?? 'Select ${widget.vehicleType} Slot', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('AVAILABLE SLOTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _slots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No ${widget.vehicleType} slots available.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Please try again later or check another type.', 
                        style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _slots.length,
                  itemBuilder: (context, index) {
                    final slot = _slots[index];
                    return _buildSlotCard(slot);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(ParkingSlot slot) {
    final bool available = slot.isAvailable;

    return GestureDetector(
      onTap: available ? () => _navigateToBooking(slot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: available ? AppColors.success.withOpacity(0.5) : AppColors.error.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (available ? AppColors.success : AppColors.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_parking,
                color: available ? AppColors.success : AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Slot ${slot.slotNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              available ? 'Available' : 'Occupied',
              style: TextStyle(
                color: available ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (available)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '₹${slot.pricePerHour}/hr',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToBooking(ParkingSlot slot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(slot: slot),
      ),
    );
  }
}
