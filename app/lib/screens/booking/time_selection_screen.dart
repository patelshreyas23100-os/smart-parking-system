import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import 'cart_summary_screen.dart';

class TimeSelectionScreen extends StatefulWidget {
  const TimeSelectionScreen({super.key});

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  late DateTime _entryTime;
  late DateTime _exitTime;
  bool _isExitNextDay = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _entryTime = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _exitTime = _entryTime.add(const Duration(hours: 1));
    _isExitNextDay = _exitTime.day != _entryTime.day;
  }

  void _updateTime(bool isEntry, int hour, int minute, bool isPM) {
    setState(() {
      final now = DateTime.now();
      int h = isPM ? (hour % 12 + 12) : (hour % 12);
      
      if (isEntry) {
        _entryTime = DateTime(now.year, now.month, now.day, h, minute);
        // Force exit to be after entry if it's on same day
        if (!_isExitNextDay && _exitTime.isBefore(_entryTime)) {
          _exitTime = _entryTime.add(const Duration(hours: 1));
          _isExitNextDay = _exitTime.day != _entryTime.day;
        }
      } else {
        DateTime newExit = DateTime(_entryTime.year, _entryTime.month, _entryTime.day, h, minute);
        if (_isExitNextDay) {
          newExit = newExit.add(const Duration(days: 1));
        }
        _exitTime = newExit;
      }
    });
  }

  void _toggleNextDay(bool value) {
    setState(() {
      _isExitNextDay = value;
      if (_isExitNextDay) {
        if (_exitTime.day == _entryTime.day) {
          _exitTime = _exitTime.add(const Duration(days: 1));
        }
      } else {
        if (_exitTime.day != _entryTime.day) {
          _exitTime = _exitTime.subtract(const Duration(days: 1));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = _exitTime.difference(_entryTime);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Select Time')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Entry Time'),
            const SizedBox(height: 12),
            _buildTimePickerCard(true),
            
            const SizedBox(height: 32),
            
            _buildSectionHeader('Exit Time'),
            const SizedBox(height: 12),
            _buildTimePickerCard(false),
            
            const SizedBox(height: 12),
            _buildNextDayToggle(),
            
            const SizedBox(height: 40),
            _buildDurationSummary(duration),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (duration.isNegative || duration.inMinutes == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Exit time must be after entry time.')));
                  return;
                }
                Provider.of<BookingProvider>(context, listen: false).setTimes(_entryTime, _exitTime);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartSummaryScreen()));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm & Proceed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
  }

  Widget _buildTimePickerCard(bool isEntry) {
    final time = isEntry ? _entryTime : _exitTime;
    int displayHour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    bool isPM = time.hour >= 12;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeColumn('Hour', displayHour, 1, 12, (v) => _updateTime(isEntry, v, time.minute, isPM)),
          const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          _buildTimeColumn('Min', time.minute, 0, 55, (v) => _updateTime(isEntry, time.hour % 12, v, isPM), step: 5),
          _buildAmPmToggle(isPM, (v) => _updateTime(isEntry, displayHour, time.minute, v)),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, int value, int min, int max, Function(int) onChanged, {int step = 1}) {
    return Column(
      children: [
        IconButton(icon: const Icon(Icons.keyboard_arrow_up), onPressed: () {
          int next = value + step;
          if (next > max) next = min;
          onChanged(next);
        }),
        Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
        IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () {
          int next = value - step;
          if (next < min) next = max;
          onChanged(next);
        }),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAmPmToggle(bool isPM, Function(bool) onChanged) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onChanged(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: !isPM ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('AM', style: TextStyle(fontWeight: FontWeight.bold, color: !isPM ? Colors.white : AppColors.textSecondary)),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onChanged(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPM ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('PM', style: TextStyle(fontWeight: FontWeight.bold, color: isPM ? Colors.white : AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _buildNextDayToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: _isExitNextDay ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text('Exit on the Next Day?', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Switch(
            value: _isExitNextDay,
            onChanged: _toggleNextDay,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSummary(Duration duration) {
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('Total Parking Duration', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            '${hours}h ${mins}m',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          if (_isExitNextDay)
            const Padding(
              padding: EdgeInsets.top(4),
              child: Text('(Overnight Booking)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
