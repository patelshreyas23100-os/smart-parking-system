import 'package:flutter/material.dart';
import '../../models/subscription_plan.dart';
import '../../models/user_subscription.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<SubscriptionPlan> _plans = [];
  List<UserSubscription> _mySubscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _apiService.getSubscriptionPlans();
      final mySubs = await _apiService.getMySubscriptions();
      if (mounted) {
        setState(() {
          _plans = plans;
          _mySubscriptions = mySubs.where((s) => s.status == 'Active').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPaymentDialog(SubscriptionPlan plan) {
    String paymentMethod = 'Wallet';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Confirm Purchase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan: ${plan.name}'),
                  Text('Price: ₹${plan.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Payment Method:'),
                  DropdownButton<String>(
                    value: paymentMethod,
                    isExpanded: true,
                    items: ['Wallet', 'UPI']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => paymentMethod = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (paymentMethod == 'UPI') {
                      _showUPIDialog(plan);
                    } else {
                      _purchasePlan(plan.id, paymentMethod);
                    }
                  },
                  child: const Text('PAY'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showUPIDialog(SubscriptionPlan plan) {
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
                hintText: 'e.g., name@okicici',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final upiId = upiController.text.trim();
              if (upiId.isEmpty || !RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$').hasMatch(upiId)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid UPI ID (e.g., name@okicici)')));
                return;
              }
              Navigator.pop(context);
              _purchasePlan(plan.id, 'UPI');
            },
            child: const Text('PAY NOW'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchasePlan(int planId, String paymentMethod) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.purchaseSubscription(planId, paymentMethod);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription Activated!')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Subscriptions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_mySubscriptions.isNotEmpty) ...[
                    const Text('Active Subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    ..._mySubscriptions.map(_buildActiveSub),
                    const SizedBox(height: 24),
                  ],
                  const Text('Available Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  ..._plans.map(_buildPlanCard),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveSub(UserSubscription sub) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.success, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Valid till: ${dateFormat.format(sub.endDate)}', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('₹${plan.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Vehicle Type: ${plan.vehicleType}', style: const TextStyle(color: AppColors.textSecondary)),
            Text('Duration: ${plan.durationDays} Days', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPaymentDialog(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Subscribe Now', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
