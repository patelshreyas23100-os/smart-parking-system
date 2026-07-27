import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'select_slot_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import '../utils/constants.dart';
import '../models/parking_location.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _currentPosition;
  bool _isLocating = false;
  GoogleMapController? _mapController;
  
  final LatLng _center = const LatLng(23.0225, 72.5714); // Ahmedabad Center

  final Set<Marker> _markers = {};
  
  final _apiService = ApiService();
  List<LocationSuggestion> _suggestions = [];
  List<ParkingLocation> _nearbyLocations = [];
  ParkingLocation? _selectedLocation;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadAllLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllLocations() async {
    try {
      final results = await _apiService.getNearbyParking("");
      setState(() {
        _nearbyLocations = results;
        _updateMarkers(results);
      });
    } catch (e) {
      debugPrint("Error loading locations: $e");
    }
  }

  void _initMarkers() {
    // Legacy - replaced by _loadAllLocations
  }

  Future<void> _getCurrentLocation() async {
    if (Platform.isWindows) return; // Geolocator may have issues on Windows without extra setup
    
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLocating = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isLocating = false);
    }
  }

  void _selectLocation(String query) async {
    // Selection now handled exclusively by marker tapping
  }

  void _updateMarkers(List<ParkingLocation> locations) {
    setState(() {
      _markers.clear();
      for (var loc in locations) {
        _markers.add(
          Marker(
            markerId: MarkerId(loc.id.toString()),
            position: LatLng(loc.latitude, loc.longitude),
            infoWindow: InfoWindow(
              title: loc.name,
              snippet: '₹${loc.pricePerHour.toStringAsFixed(2)}/hr • ${loc.availableSlots} available',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              loc.id == _selectedLocation?.id ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure
            ),
            onTap: () {
              _onMarkerTapped(loc);
            },
          ),
        );
      }
    });
  }

  void _onMarkerTapped(ParkingLocation loc) {
    setState(() {
      _selectedLocation = loc;
    });
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(loc.latitude, loc.longitude)),
      );
    }
  }

  void _showVehicleTypeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Select Vehicle Type',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text('Choose your vehicle to find matching slots', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 30),
            _buildTypeOption(
              icon: Icons.motorcycle,
              label: 'Two-Wheeler',
              onTap: () => _navigateToSlots('Two-Wheeler'),
            ),
            const SizedBox(height: 16),
            _buildTypeOption(
              icon: Icons.directions_car,
              label: 'Four-Wheeler',
              onTap: () => _navigateToSlots('Four-Wheeler'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToSlots(String type) {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectSlotScreen(
          vehicleType: type, 
          locationId: _selectedLocation?.id,
          locationName: _selectedLocation?.name,
        ),
      ),
    );
  }

  Widget _buildTypeOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: AppColors.primary, size: 30),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: AppColors.textHint),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      tileColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = Platform.isWindows;

    return Scaffold(
      body: Stack(
        children: [
          // Map Section
          if (isWindows)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=2000'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
                ),
              ),
              child: Stack(
                children: [
                   // Simulated Markers
                  ... [
                    {'lat': 0.1, 'lng': 0.2, 'name': 'Alpha Mall'},
                    {'lat': -0.15, 'lng': -0.3, 'name': 'Iskcon Crossing'},
                    {'lat': 0.25, 'lng': -0.1, 'name': 'Prahlad Nagar'},
                  ].map((m) => Align(
                    alignment: Alignment(m['lat'] as double, m['lng'] as double),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(m['name'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.location_on, color: AppColors.error, size: 40),
                      ],
                    ),
                  )),
                  // Info Overlay
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'Desktop View: Simulated Map',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Live Google Map is optimized for Android & iOS.\nBooking flow is fully functional below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          
          // Search Header Removed
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildFab(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Bottom Action Area
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildFab(Icons.my_location, _getCurrentLocation),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.local_parking, color: AppColors.primary),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedLocation?.name ?? 'Search Location', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(_selectedLocation != null 
                                  ? '${_selectedLocation!.area} • Starts at ₹${_selectedLocation!.pricePerHour.toStringAsFixed(2)}/hr'
                                  : '4 parking zones nearby', 
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (_selectedLocation != null)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                               decoration: BoxDecoration(
                                 color: AppColors.success.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Text('${_selectedLocation!.availableSlots}/${_selectedLocation!.totalSlots}', 
                                 style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                             ),
                        ],
                      ),
                      if (_nearbyLocations.length > 1) ... [
                        const SizedBox(height: 15),
                        const Divider(),
                        const SizedBox(height: 10),
                        const Text('NEARBY PARKING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textHint)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _nearbyLocations.length - 1,
                            itemBuilder: (context, index) {
                              final loc = _nearbyLocations[index + 1];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedLocation = loc),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _selectedLocation == loc ? AppColors.primary : Colors.transparent),
                                  ),
                                  child: Center(child: Text(loc.name, style: const TextStyle(fontSize: 12))),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => _showVehicleTypeSelection(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: Text(_selectedLocation != null ? 'Book at ${_selectedLocation!.name}' : 'View All Slots', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15)],
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
