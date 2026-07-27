import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'profile/add_vehicle_screen.dart';
import 'profile/edit_profile_screen.dart';
import 'profile/subscription_plans_screen.dart';
import 'profile/contact_us_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_navigation.dart';
import '../models/user.dart'; // Kept from original, as it's used
import 'welcome_screen.dart'; // Kept from original, as it's used
import 'profile/my_vehicles_screen.dart'; // Kept from original, as it's used
import 'recharge_wallet_screen.dart'; // Kept from original, as it's used

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _apiService = ApiService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getMe();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(_user?.name[0].toUpperCase() ?? 'U', 
                        style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Text(_user?.name ?? 'Loading...', 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildProfileItem(Icons.phone, 'Phone', _user?.phone ?? 'N/A', () async {
                if (_user == null) return;
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      currentName: _user!.name,
                      currentPhone: _user!.phone,
                      currentLicenceNo: _user!.licenceNo,
                    )
                  )
                );
                if (result == true) _loadUser();
              }),
              _buildProfileItem(Icons.badge, 'Licence Number', _user?.licenceNo.isNotEmpty == true ? _user!.licenceNo : 'Not Set', () async {
                if (_user == null) return;
                final result = await Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      currentName: _user!.name,
                      currentPhone: _user!.phone,
                      currentLicenceNo: _user!.licenceNo,
                    )
                  )
                );
                if (result == true) _loadUser();
              }),
              _buildProfileItem(Icons.account_balance_wallet, 'Wallet Balance', '₹ ${_user?.walletBalance.toStringAsFixed(2) ?? '0.00'}', () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const RechargeWalletScreen()));
                if (result == true) _loadUser();
              }),
              _buildProfileItem(Icons.card_membership, 'My Subscriptions', 'View Plans', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscriptionPlansScreen()),
                ).then((_) => _loadUser());
              }),
              _buildProfileItem(Icons.directions_car, 'My Vehicles', 'Manage your cars/bikes', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyVehiclesScreen()));
              }),
              _buildProfileItem(Icons.contact_support, 'Contact Us', 'Get help from our team', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
              }),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_user == null) return;
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        currentName: _user!.name,
                        currentPhone: _user!.phone,
                        currentLicenceNo: _user!.licenceNo,
                      )
                    )
                  );
                  if (result == true) _loadUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
