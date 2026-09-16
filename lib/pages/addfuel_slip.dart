import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/fuel_models.dart';
import '../services/fuel_repository.dart';
import '../services/ocr_service.dart'; // Import OCR helper
import '../services/maintenance_service.dart'; // Import Maintenance helper

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
  bool _isScanningOcr = false; // OCR scan state

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _pricePerUnitController = TextEditingController();
  final _volumeController = TextEditingController();
  final _odometerController = TextEditingController();
  final _vatController = TextEditingController();

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
    try {
      final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
      final effectiveSource = isDesktop ? ImageSource.gallery : source;

      final picked = await _picker.pickImage(source: effectiveSource, imageQuality: 80);
      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          _imageFile = file;
          _isScanningOcr = true;
        });

        // Trigger OCR scan on the selected slip image
        await _processReceiptOcr(file);
      }
    } catch (e) {
      _showSnackBar('Failed to select image: $e');
    } finally {
      if (mounted) setState(() => _isScanningOcr = false);
    }
  }

  Future<void> _processReceiptOcr(File file) async {
    try {
      final ocrResult = await OcrService.scanReceipt(file);

      // Auto-populate form fields if values were extracted
      if (ocrResult.merchantName != null && _merchantController.text.isEmpty) {
        _merchantController.text = ocrResult.merchantName!;
      }
      if (ocrResult.totalAmount != null) {
        _amountController.text = ocrResult.totalAmount!.toStringAsFixed(2);
      }
      if (ocrResult.pricePerUnit != null) {
        _pricePerUnitController.text = ocrResult.pricePerUnit!.toStringAsFixed(2);
      }
      if (ocrResult.volumeUnits != null) {
        _volumeController.text = ocrResult.volumeUnits!.toStringAsFixed(2);
      }
      if (ocrResult.vatAmount != null) {
        _vatController.text = ocrResult.vatAmount!.toStringAsFixed(2);
      }

      // If price and total exist but volume missing, calculate volume mathematically
      if (ocrResult.totalAmount != null && ocrResult.pricePerUnit != null && ocrResult.volumeUnits == null) {
        final calculatedVol = ocrResult.totalAmount! / ocrResult.pricePerUnit!;
        _volumeController.text = calculatedVol.toStringAsFixed(2);
      }

      _showSnackBar('Receipt scanned! Check and verify extracted data.');
    } catch (e) {
      _showSnackBar('OCR Scan skipped: Could not read receipt text.');
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
        totalAmount: double.tryParse(_amountController.text) ?? 0.0,
        pricePerUnit: double.tryParse(_pricePerUnitController.text) ?? 0.0,
        volumeUnits: double.tryParse(_volumeController.text) ?? 0.0,
        odometerReading: int.tryParse(_odometerController.text) ?? 0,
        transactionDate: DateTime.now(),
        vatAmount: double.tryParse(_vatController.text) ?? 0.0,
      );

// RUN MAINTENANCE CHECK
      final currentOdometer = int.tryParse(_odometerController.text) ?? 0;
      final schedules = await _repo.getMaintenanceSchedules(_selectedVehicleId!);
      final alerts = MaintenanceService.checkSchedules(
        currentOdometer: currentOdometer,
        schedules: schedules,
      );

      if (mounted) {
        _showSnackBar('Fuel slip saved successfully!');
        Navigator.pop(context);

        //After Saving Slip, Calcuate the Efficency of the Vehicle and Update the Vehicle's Efficiency in the Database
        
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
                // Image Box with Scanning Status Overlay
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _isScanningOcr
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Scanning receipt text...'),
                            ],
                          )
                        : _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to capture or select slip photo'),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),

                // Vehicle Selector
                DropdownButtonFormField<String>(
                  value: _selectedVehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle', border: OutlineInputBorder(), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey))),
                  items: _vehicles
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.make} ${v.model} (${v.registrationNumber})'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedVehicleId = val),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant Name',
                    hintText: 'e.g. Shell, Engen, BP',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),

              const SizedBox(height: 12),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount (ZAR)',
                    prefixText: 'R ',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _pricePerUnitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price per Litre',
                    prefixText: 'R ',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volume (Litres)',
                    suffixText: 'L',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _vatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'VAT Amount (ZAR)',
                    prefixText: 'R ',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Odometer Reading',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12.0)), borderSide: BorderSide(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Fuel Slip', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}