import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/vehicles_page.dart';
import '../services/fuel_repository.dart';
import '../services/auth_service.dart';
import '../pages/addfuel_slip.dart';
import '../pages/add_vehicle_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _fuelRepo = FuelRepository();

  List<Map<String, dynamic>> _fuelSlips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFuelSlips();
  }

  Future<void> _fetchFuelSlips() async {
    setState(() => _isLoading = true);
    try {
      final slips = await _fuelRepo.getFuelSlips();
      setState(() {
        _fuelSlips = slips;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching slips: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalSpend => _fuelSlips.fold(
      0.0, (sum, slip) => sum + ((slip['total_amount'] as num?)?.toDouble() ?? 0.0));

  double get _totalLitres => _fuelSlips.fold(
      0.0, (sum, slip) => sum + ((slip['volume_units'] as num?)?.toDouble() ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await _authService.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          
          children: [
            //Drawer Header
            const DrawerHeader(child: Text('Menu')),

            // Drawer Items
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Manage Vehicles'),
              onTap: () {
                // Navigate to vehicle management page
                Navigator.push(context, MaterialPageRoute(builder: (context) => const VehiclesPage()));
              },
            ),
          ]
        )
      ), // Placeholder for future navigation drawer to manage vehicles, settings, etc.
      body: RefreshIndicator(
        onRefresh: _fetchFuelSlips,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // User Info Header
                  Text(
                    'Welcome, ${userEmail ?? "User"}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),

                  // Overview Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Spend',
                          value: 'R ${_totalSpend.toStringAsFixed(2)}',
                          icon: Icons.payments,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Litres',
                          value: '${_totalLitres.toStringAsFixed(1)} L',
                          icon: Icons.local_gas_station,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Fuel Slips',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text('${_fuelSlips.length} logs'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fuel Slips List
                  if (_fuelSlips.isEmpty)
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: const Text('No fuel slips added yet. Tap + below to add one.'),
                    )
                  else
                    ..._fuelSlips.map((slip) => _FuelSlipCard(slip: slip, repo: _fuelRepo)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFuelSlipPage()),
          );
          _fetchFuelSlips(); // Refresh list when returning from Add page
        },
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Slip'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _FuelSlipCard extends StatelessWidget {
  final Map<String, dynamic> slip;
  final FuelRepository repo;

  const _FuelSlipCard({required this.slip, required this.repo});

  @override
  Widget build(BuildContext context) {
    final vehicle = slip['vehicles'] as Map<String, dynamic>?;
    final vehicleText = vehicle != null
        ? '${vehicle['make']} ${vehicle['model']} (${vehicle['registration_number']})'
        : 'Unknown Vehicle';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Private Image Thumbnail Handler
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<String>(
                future: repo.getSignedImageUrl(slip['image_path']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  if (snapshot.hasData) {
                    return Image.network(
                      snapshot.data!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.receipt, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Slip Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slip['merchant_name'] ?? 'Fuel Station',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicleText,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${slip['volume_units']} L @ R${slip['price_per_unit']}/L • Odo: ${slip['odometer_reading']} km',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),

            // Amount Display
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R ${(slip['total_amount'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slip['transaction_date'] ?? '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}