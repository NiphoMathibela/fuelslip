import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FuelEfficiencyPoint {
  final DateTime date;
  final double l100km;

  FuelEfficiencyPoint({required this.date, required this.l100km});
}

class VehicleData {
  final String id;
  final String name;
  final double monthlyForecast;
  final double avgCostPerKm;
  final double currentAvgL100km;
  final List<FuelEfficiencyPoint> efficiencyHistory;

  VehicleData({
    required this.id,
    required this.name,
    required this.monthlyForecast,
    required this.avgCostPerKm,
    required this.currentAvgL100km,
    required this.efficiencyHistory,
  });
}

class VehicleDashboardWidget extends StatefulWidget {
  const VehicleDashboardWidget({super.key});

  @override
  State<VehicleDashboardWidget> createState() => _VehicleDashboardWidgetState();
}

class _VehicleDashboardWidgetState extends State<VehicleDashboardWidget> {
  bool _isLoading = true;
  String? _selectedVehicleId;
  List<VehicleData> _vehicles = [];
  VehicleData? _currentVehicle;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // TODO: Replace mock data with your repository/database call, e.g., await _repo.getVehicles();
    await Future.delayed(const Duration(milliseconds: 300));

    final mockVehicles = [
      VehicleData(
        id: 'v1',
        name: 'Audi A3 1.0 TFSI',
        monthlyForecast: 1850.00,
        avgCostPerKm: 1.45,
        currentAvgL100km: 6.8,
        efficiencyHistory: [
          FuelEfficiencyPoint(date: DateTime.now().subtract(const Duration(days: 20)), l100km: 7.2),
          FuelEfficiencyPoint(date: DateTime.now().subtract(const Duration(days: 10)), l100km: 6.9),
          FuelEfficiencyPoint(date: DateTime.now(), l100km: 6.8),
        ],
      ),
      VehicleData(
        id: 'v2',
        name: 'BMW 323i',
        monthlyForecast: 2900.00,
        avgCostPerKm: 2.30,
        currentAvgL100km: 10.4,
        efficiencyHistory: [
          FuelEfficiencyPoint(date: DateTime.now().subtract(const Duration(days: 25)), l100km: 11.1),
          FuelEfficiencyPoint(date: DateTime.now().subtract(const Duration(days: 12)), l100km: 10.6),
          FuelEfficiencyPoint(date: DateTime.now(), l100km: 10.4),
        ],
      ),
    ];

    if (mounted) {
      setState(() {
        _vehicles = mockVehicles;
        if (_vehicles.isNotEmpty) {
          _selectedVehicleId = _vehicles.first.id;
          _currentVehicle = _vehicles.first;
        }
        _isLoading = false;
      });
    }
  }

  void _onVehicleChanged(String? newId) {
    if (newId == null) return;
    setState(() {
      _selectedVehicleId = newId;
      _currentVehicle = _vehicles.firstWhere((v) => v.id == newId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicles.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No vehicles available.')),
      );
    }

    final vehicle = _currentVehicle!;

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Selector Dropdown
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedVehicleId,
                  isExpanded: true,
                  icon: const Icon(Icons.directions_car),
                  items: _vehicles.map((v) {
                    return DropdownMenuItem<String>(
                      value: v.id,
                      child: Text(
                        v.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: _onVehicleChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
      
          // Summary Cards Section
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Est. Monthly Spend',
                  value: 'R ${vehicle.monthlyForecast.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.blue.shade700,
                  subtitle: 'Based on 30-day usage',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Cost / Km',
                  value: 'R ${vehicle.avgCostPerKm.toStringAsFixed(2)}',
                  icon: Icons.speed_outlined,
                  color: Colors.teal.shade700,
                  subtitle: 'Avg running cost',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Avg Efficiency',
                  value: '${vehicle.currentAvgL100km.toStringAsFixed(1)} L/100km',
                  icon: Icons.local_gas_station_outlined,
                  color: Colors.orange.shade800,
                  subtitle: 'Target: < 8.5 L/100km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
      
          // Efficiency Chart Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fuel Efficiency Trend',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'L / 100 km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: vehicle.efficiencyHistory.isEmpty
                        ? const Center(child: Text('Not enough fill-up data yet.'))
                        : _buildLineChart(context, vehicle.efficiencyHistory),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<FuelEfficiencyPoint> history) {
    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.l100km);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < history.length) {
                  final dt = history[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '${dt.day}/${dt.month}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue.shade600,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.shade500.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}