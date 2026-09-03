import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/fuel_repository.dart';
import '../models/fuel_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddFuelSlipPage extends StatefulWidget {
  const AddFuelSlipPage({super.key});

  @override
  State<AddFuelSlipPage> createState() => _AddFuelSlipPageState();
}

class _AddFuelSlipPageState extends State<AddFuelSlipPage> {
  final _repo = FuelRepository();
  final _picker = ImagePicker();

  File? _imageFile;
  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;
  bool _isLoading = false;

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _volumeController = TextEditingController();
  final _odometerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final list = await _repo.getVehicles();
      setState(() {
        _vehicles = list;
        if (list.isNotEmpty) _selectedVehicleId = list.first.id;
      });
    } catch (e) {
      _showSnackBar('Error loading vehicles: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // final picked = await _picker.pickImage(source: source, imageQuality: 80);
    // if (picked != null) {
    //   setState(() => _imageFile = File(picked.path));
    // }

    try {
    // Windows/macOS/Linux desktop platforms do not support ImageSource.camera
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final effectiveSource = isDesktop ? ImageSource.gallery : source;

    final picked = await _picker.pickImage(
      source: effectiveSource,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  } catch (e) {
    _showSnackBar('Failed to pick image: $e');
  }
  }

  void _submit() async {
    if (_imageFile == null) {
      _showSnackBar('Please select or capture a fuel slip photo');
      return;
    }
    if (_selectedVehicleId == null) {
      _showSnackBar('Please select a vehicle');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repo.saveFuelSlip(
        imageFile: _imageFile!,
        vehicleId: _selectedVehicleId!,
        merchantName: _merchantController.text.trim(),
        totalAmount: double.parse(_amountController.text),
        pricePerUnit: double.parse(_pricePerUnitController.text),
        volumeUnits: double.parse(_volumeController.text),
        odometerReading: int.parse(_odometerController.text),
        transactionDate: DateTime.now(),
      );

      if (mounted) {
        _showSnackBar('Fuel slip saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Failed to save slip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Fuel Slip')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Image Picker Box
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to capture slip photo'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
                  items: _vehicles
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.make} ${v.model} (${v.registrationNumber})'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedVehicleId = val),
                ),

                TextField(
                  controller: _merchantController,
                  decoration: const InputDecoration(labelText: 'Merchant (e.g. Shell, Engen)'),
                ),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total Amount (ZAR)'),
                ),
                TextField(
                  controller: _pricePerUnitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price per Litre (R)'),
                ),
                TextField(
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Volume (Litres)'),
                ),
                TextField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Odometer Reading (km)'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Fuel Slip'),
                ),
              ],
            ),
    );
  }
}