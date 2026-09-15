import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptOcrData {
  final double? totalAmount;
  final double? pricePerUnit;
  final double? volumeUnits;
  final String? merchantName;
  final double? vatAmount;
  final String rawText;

  ReceiptOcrData({
    this.totalAmount,
    this.pricePerUnit,
    this.volumeUnits,
    this.merchantName,
    this.vatAmount,
    required this.rawText,
  });
}

class OcrService {
  static Future<ReceiptOcrData> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final String text = recognizedText.text;

    // --- REGEX PATTERNS ---
    // Extract totals (e.g., R 550.00, ZAR 450, 450.50 TOTAL)
    double? totalAmount;
    final totalRegex = RegExp(
      r'(?:TOTAL|AMOUNT|DUE|R|ZAR)\s*[:=]?\s*R?\s*(\d+[.,]\d{2})',
      caseSensitive: false,
    );
    final totalMatch = totalRegex.firstMatch(text);
    if (totalMatch != null) {
      totalAmount = double.tryParse(totalMatch.group(1)!.replaceAll(',', '.'));
    }

    // Extract litres / volume (e.g., 22.50 L, 20.000 Litres, 18.5l)
    double? volumeUnits;
    final volumeRegex = RegExp(
      r'(\d+[.,]\d{2,3})\s*(?:L|Ltrs|Litres|Litre)',
      caseSensitive: false,
    );
    final volumeMatch = volumeRegex.firstMatch(text);
    if (volumeMatch != null) {
      volumeUnits = double.tryParse(volumeMatch.group(1)!.replaceAll(',', '.'));
    }

    // Extract Price per Litre (e.g., R/L 22.45, 23.50 /L, @ 22.10)
    double? pricePerUnit;
    final priceRegex = RegExp(
      r'(?:@|R/L|R/Litre|$/L)\s*[:=]?\s*R?\s*(\d+[.,]\d{2})',
      caseSensitive: false,
    );
    final priceMatch = priceRegex.firstMatch(text);
    if (priceMatch != null) {
      pricePerUnit = double.tryParse(priceMatch.group(1)!.replaceAll(',', '.'));
    }

    // Extract Merchant Name (usually standard station names near the top)
    String? merchantName;
    final lines = text.split('\n');
    for (var line in lines.take(5)) {
      final l = line.toUpperCase();
      if (l.contains('SHELL')) merchantName = 'Shell';
      if (l.contains('ENGEN')) merchantName = 'Engen';
      if (l.contains('BP')) merchantName = 'BP';
      if (l.contains('TOTAL')) merchantName = 'Total Energies';
      if (l.contains('SASOL')) merchantName = 'Sasol';
      if (l.contains('CALTEX') || l.contains('ASTRON')) merchantName = 'Astron Energy';
    }

    // Extract VAT Amount (e.g., VAT 15% R 75.00)
    double? vatAmount;
    final vatRegex = RegExp(
      r'VAT\s*[:=]?\s*\d+%?\s*R?\s*(\d+[.,]\d{2})',
      caseSensitive: false,
    );
    final vatMatch = vatRegex.firstMatch(text);
    if (vatMatch != null) {
      vatAmount = double.tryParse(vatMatch.group(1)!.replaceAll(',', '.'));
    }

    return ReceiptOcrData(
      totalAmount: totalAmount,
      pricePerUnit: pricePerUnit,
      volumeUnits: volumeUnits,
      merchantName: merchantName,
      vatAmount: vatAmount,
      rawText: text,
    );
  }
}