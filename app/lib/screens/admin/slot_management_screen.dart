import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../models/parking_slot.dart';

class SlotManagementScreen extends StatefulWidget {
  const SlotManagementScreen({super.key});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
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
      final slots = await _apiService.getAllSlots();
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability(ParkingSlot slot) async {
    try {
      await _apiService.updateSlot(slot.id, !slot.isAvailable);
      _loadSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Slot Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _slots.length,
              itemBuilder: (context, index) {
                final slot = _slots[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: slot.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_parking,
                          color: slot.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text('Slot ${slot.slotNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${slot.location} • ${slot.type}'),
                      trailing: Switch(
                        value: slot.isAvailable,
                        onChanged: (_) => _toggleAvailability(slot),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
