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

  /// --- MANAGE VEHICLE ---
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

  /// Uploads slip image to `fuel-slips` bucket under `user_id/timestamp.jpg`
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
    required double pricePerUnit,
    required double volumeUnits,
    required int odometerReading,
    required DateTime transactionDate,
  }) async {
    // 1. Upload image first
    final imagePath = await uploadSlipImage(imageFile);

    // 2. Insert record into fuel_slips table
    final slip = FuelSlip(
      vehicleId: vehicleId,
      merchantName: merchantName,
      transactionDate: transactionDate,
      totalAmount: totalAmount,
      pricePerUnit: pricePerUnit,
      volumeUnits: volumeUnits,
      odometerReading: odometerReading,
      imagePath: imagePath,
    );

    await _supabase.from('fuel_slips').insert(slip.toJson(_currentUserId));
  }

  /// Generates a temporary signed URL to safely render private slip images
  Future<String> getSignedImageUrl(String imagePath) async {
    return await _supabase.storage
        .from('fuel-slips')
        .createSignedUrl(imagePath, 60 * 60); // 1 hour validity
  }

  /// Fetches all fuel slips for the authenticated user
  Future<List<Map<String, dynamic>>> getFuelSlips() async {
    final response = await _supabase
        .from('fuel_slips')
        .select('*, vehicles(make, model, registration_number)')
        .eq('user_id', _currentUserId)
        .order('transaction_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}