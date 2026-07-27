import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../models/parking_slot.dart';
import '../models/vehicle.dart';
import 'package:intl/intl.dart';
import 'profile/add_vehicle_screen.dart';
import 'main_navigation.dart';
import '../models/user_subscription.dart';

class BookingDetailsScreen extends StatefulWidget {
  final ParkingSlot slot;

  const BookingDetailsScreen({super.key, required this.slot});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _apiService = ApiService();
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  DateTime _startTime = DateTime.now().add(const Duration(minutes: 5));
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1, minutes: 5));
  String _paymentMethod = 'Wallet';
  bool _isLoading = true;
  bool _isBooking = false;
  bool _hasActiveSubscription = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final subs = await _apiService.getMySubscriptions();
      final activeSub = subs.where((s) => s.status == 'Active' && s.plan.vehicleType == widget.slot.type).isNotEmpty;
      if (mounted && activeSub) {
        setState(() => _hasActiveSubscription = true);
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await _apiService.getVehicles();
      setState(() {
        // Filter vehicles to match the slot type (with aliases)
        _vehicles = vehicles.where((v) {
          final vt = v.type.toLowerCase();
          final st = widget.slot.type.toLowerCase();
          if (st == 'two-wheeler') {
            return vt == 'two-wheeler' || vt == 'bike' || vt == 'motorcycle';
          }
          return vt == st;
        }).toList();
        if (_vehicles.isNotEmpty) _selectedVehicle = _vehicles.first;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalPrice {
    if (_hasActiveSubscription) return 0.0;
    final durationInHours = _endTime.difference(_startTime).inMinutes / 60.0;
    return durationInHours * widget.slot.pricePerHour;
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      initialEntryMode: TimePickerEntryMode.inputOnly, // Force input mode for easier desktop use
      helpText: isStart ? 'Select Entry Time' : 'Select Exit Time',
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final newTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        if (isStart) {
          _startTime = newTime;
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          if (newTime.isAfter(_startTime)) {
            _endTime = newTime;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exit time must be after entry time')),
            );
          }
        }
      });
    }
  }

  Future<void> _showConfirmationDialog(VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to book this slot?'),
            const SizedBox(height: 16),
            if (!_hasActiveSubscription)
              Text('Payment Method: $_paymentMethod', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Total Amount: ₹${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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

  void _showUPIDialog() {
    final upiController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter UPI ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your UPI ID to proceed with the payment.'),
            const SizedBox(height: 16),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(
                hintText: 'e.g., yourname@upi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final upiId = upiController.text.trim();
              if (upiId.isEmpty || !RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(upiId)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid UPI ID (e.g., name@okicici)')));
                return;
              }
              Navigator.pop(context); // Close dialog
              _processBooking(); // Continue to process the booking
            },
            child: const Text('PAY NOW'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBooking() async {
    setState(() => _isBooking = true);
    try {
      await _apiService.createBooking(
        widget.slot.id,
        _selectedVehicle!.id,
        _startTime,
        _endTime,
        _hasActiveSubscription ? 'Subscription' : _paymentMethod,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 60),
                SizedBox(height: 16),
                Text('Booking Successful!'),
              ],
            ),
            content: const Text('Your parking spot has been reserved. You can view details in History.', textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainNavigation()),
                    (route) => false,
                  );
                },
                child: const Text('Go Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vehicle')));
      return;
    }

    if (!_hasActiveSubscription && _paymentMethod == 'UPI') {
      _showUPIDialog();
      return;
    }

    _showConfirmationDialog(() => _processBooking());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Slot Information'),
                  _buildInfoCard(
                    child: Row(
                      children: [
                        const Icon(Icons.local_parking, color: AppColors.primary, size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Slot ${widget.slot.slotNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('${widget.slot.type} Parking', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                        const Spacer(),
                        Text('₹${widget.slot.pricePerHour.toStringAsFixed(2)}/hr', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Select Vehicle'),
                  _vehicles.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You have no ${_vehicles.isEmpty ? widget.slot.type : ""} vehicles added.',
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                                );
                                if (result == true) _loadVehicles();
                              },
                              icon: const Icon(Icons.add),
                              label: Text('Add ${widget.slot.type}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ],
                        )
                      : _buildInfoCard(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Vehicle>(
                              isExpanded: true,
                              value: _selectedVehicle,
                              hint: const Text('Choose a vehicle'),
                              items: _vehicles.map((v) => DropdownMenuItem(
                                value: v,
                                child: Text('${v.name} (${v.plateNumber})'),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedVehicle = v),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Duration'),
                  Row(
                    children: [
                      Expanded(child: _buildTimePicker('Entry Time', _startTime, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTimePicker('Exit Time', _endTime, false)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_hasActiveSubscription) ...[
                    _buildSectionTitle('Payment Method'),
                    _buildPaymentOption('Wallet', Icons.account_balance_wallet),
                    _buildPaymentOption('UPI', Icons.phone_android),
                    _buildPaymentOption('Cash', Icons.money),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_hasActiveSubscription)
                            const Text('Subscription Applied', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('₹ ${_totalPrice.toStringAsFixed(2)}', 
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isBooking ? null : _handleBooking,
                    child: _isBooking 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Booking'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildTimePicker(String label, DateTime time, bool isStart) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickTime(isStart),
        borderRadius: BorderRadius.circular(16),
        child: _buildInfoCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(DateFormat('hh:mm a').format(time), 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.access_time, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    final isSelected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
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
