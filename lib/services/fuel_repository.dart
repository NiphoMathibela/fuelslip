import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fuel_models.dart';

class FuelRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.id;
  }

  // --- VEHICLES ---

  Future<List<Vehicle>> getVehicles() async {
    final response = await _supabase
        .from('vehicles')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Vehicle.fromJson(json)).toList();
  }

  Future<Vehicle> addVehicle({
    required String make,
    required String model,
    required String registrationNumber,
    required int startingOdometer,
  }) async {
    final response = await _supabase.from('vehicles').insert({
      'user_id': _currentUserId,
      'make': make,
      'model': model,
      'registration_number': registrationNumber,
      'starting_odometer': startingOdometer,
    }).select().single();

    return Vehicle.fromJson(response);
  }

  Future<void> updateVehicle({
    required String id,
    required String make,
    required String model,
    required String registrationNumber,
    required int startingOdometer,
  }) async {
    await _supabase.from('vehicles').update({
      'make': make,
      'model': model,
      'registration_number': registrationNumber,
      'starting_odometer': startingOdometer,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', _currentUserId);
  }

  // --- STORAGE & FUEL SLIPS ---

  Future<String> uploadSlipImage(File imageFile) async {
    final userId = _currentUserId;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    await _supabase.storage.from('fuel-slips').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return path;
  }

  /// Saves the complete fuel slip record to PostgreSQL
  Future<void> saveFuelSlip({
    required File imageFile,
    required String vehicleId,
    required String merchantName,
    required double totalAmount,
    required double vatAmount,
    required double pricePerUnit,
    required double volumeUnits,
    required int odometerReading,
    required DateTime transactionDate,
  }) async {
    // 1. Upload image
    final imagePath = await uploadSlipImage(imageFile);

    // 2. Fetch last fuel slip to calculate distance & consumption
    final lastSlip = await getLatestFuelSlip(vehicleId);
    double? distanceDriven;
    double? consumptionL100km;

    if (lastSlip != null && lastSlip['odometer_reading'] != null) {
      final prevOdo = lastSlip['odometer_reading'] as int;
      if (odometerReading > prevOdo) {
        distanceDriven = (odometerReading - prevOdo).toDouble();
        consumptionL100km = (volumeUnits / distanceDriven) * 100;
      }
    }

    // 3. Prepare payload
    final slipData = {
      'user_id': _currentUserId,
      'vehicle_id': vehicleId,
      'merchant_name': merchantName,
      'transaction_date': transactionDate.toIso8601String(),
      'total_amount': totalAmount,
      'vat_amount': vatAmount,
      'price_per_unit': pricePerUnit,
      'volume_units': volumeUnits,
      'odometer_reading': odometerReading,
      'image_path': imagePath,
      'distance_driven': distanceDriven,
      'consumption_l_100km': consumptionL100km,
    };

    await _supabase.from('fuel_slips').insert(slipData);
  }

  Future<String> getSignedImageUrl(String imagePath) async {
    return await _supabase.storage
        .from('fuel-slips')
        .createSignedUrl(imagePath, 60 * 60);
  }

  Future<List<Map<String, dynamic>>> getFuelSlips() async {
    final response = await _supabase
        .from('fuel_slips')
        .select('*, vehicles(make, model, registration_number)')
        .eq('user_id', _currentUserId)
        .order('transaction_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // --- ANALYTICS & MAINTENANCE METHODS ---

  /// Gets the most recent fuel slip for a specific vehicle
  Future<Map<String, dynamic>?> getLatestFuelSlip(String vehicleId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select()
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .order('transaction_date', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Gets latest odometer reading recorded for a vehicle
  Future<int> getLatestOdometer(String vehicleId) async {
    final lastSlip = await getLatestFuelSlip(vehicleId);
    if (lastSlip != null && lastSlip['odometer_reading'] != null) {
      return lastSlip['odometer_reading'] as int;
    }

    // Fall back to vehicle starting odometer if no fuel slips exist
    final vehicleResponse = await _supabase
        .from('vehicles')
        .select('starting_odometer')
        .eq('id', vehicleId)
        .single();

    return vehicleResponse['starting_odometer'] as int? ?? 0;
  }

  /// Gets historical L/100km figures for anomaly detection and trend charts
  Future<List<double>> getHistoricalL100km(String vehicleId) async {
    final response = await _supabase
        .from('fuel_slips')
        .select('consumption_l_100km')
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId)
        .not('consumption_l_100km', 'is', null)
        .order('transaction_date', ascending: true);

    return (response as List)
        .map((e) => (e['consumption_l_100km'] as num).toDouble())
        .toList();
  }

  /// Fetches maintenance schedules for a given vehicle
  Future<List<Map<String, dynamic>>> getMaintenanceSchedules(String vehicleId) async {
    final response = await _supabase
        .from('maintenance_schedules')
        .select()
        .eq('user_id', _currentUserId)
        .eq('vehicle_id', vehicleId);

    return List<Map<String, dynamic>>.from(response);
  }
}