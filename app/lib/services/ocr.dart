// ocr_service.dart
import 'dart:developer';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class OCRService {
  static final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // Extract Sample ID from Image (QR code or barcode)
  Future<String> extractQrFromImage(String imagePath) async {
    try {
      // Create input image from file path
      final inputImage = InputImage.fromFilePath(imagePath);

      // Initialize barcode scanner with both QR and regular barcode formats
      final barcodeScanner = BarcodeScanner(formats: [
        BarcodeFormat.qrCode, 
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8
      ]);

      // Process the image
      final barcodes = await barcodeScanner.processImage(inputImage);

      // Check if any barcodes were found
      if (barcodes.isEmpty) {
        return 'No barcodes detected in image';
      }

      // Extract values from all detected barcodes
      final List<String> qrValues = [];
      for (final barcode in barcodes) {
        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
          qrValues.add(barcode.rawValue!);
        }
      }

      // Return found barcodes or error message
      if (qrValues.isEmpty) {
        return 'Barcodes detected but no valid data found';
      } else if (qrValues.length == 1) {
        return qrValues.first;
      } else {
        // Multiple barcodes found, return the first one
        log('Multiple barcodes found: ${qrValues.join(" | ")}. Using the first one.');
        return qrValues.first;
      }
    } catch (e) {
      log('Error scanning barcode: ${e.toString()}');
      return 'Error scanning barcode: ${e.toString()}';
    }
  }

  // Extract Weight from Image
  Future<String?> extractWeightFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Log recognized text for debugging
      log("OCR Raw Text: ${recognizedText.text}");

      // More robust regex patterns for digital scale displays
      final List<RegExp> weightPatterns = [
        RegExp(r'(\d+\.\d+)\s*(g|kg|G|KG)', caseSensitive: false), // "10.388 g" format
        RegExp(r'(\d+\,\d+)\s*(g|kg|G|KG)', caseSensitive: false), // "10,388 g" format (European)
        RegExp(r'(\d+\.\d+)', caseSensitive: false), // Just a decimal number
        RegExp(r'(\d+)\s*\.(\d+)', caseSensitive: false), // Separate integer and fraction
      ];

      // First try the complete text for better context
      final completeText = recognizedText.text.replaceAll(',', '.'); // Normalize commas
      
      // Try each pattern against the complete text
      for (final pattern in weightPatterns) {
        final match = pattern.firstMatch(completeText);
        if (match != null) {
          if (match.groupCount >= 2 && match.group(2) != null) {
            // Pattern with unit
            final value = match.group(1)!;
            final unit = match.group(2)!.toLowerCase();
            return '$value $unit';
          } else if (match.groupCount >= 1) {
            // Just a decimal number, assume grams
            final value = match.group(1)!;
            return '$value g';
          }
        }
      }

      // If complete match fails, try block by block
      for (final block in recognizedText.blocks) {
        // Process each line in the block
        for (final line in block.lines) {
          final text = line.text.replaceAll(',', '.').trim();
          
          // Try each pattern against this line
          for (final pattern in weightPatterns) {
            final match = pattern.firstMatch(text);
            if (match != null) {
              if (match.groupCount >= 2 && match.group(2) != null) {
                // Pattern with unit
                final value = match.group(1)!;
                final unit = match.group(2)!.toLowerCase();
                return '$value $unit';
              } else if (match.groupCount >= 1) {
                // Just a decimal number, assume grams
                final value = match.group(1)!;
                return '$value g';
              }
            }
          }
        }
      }

      // If still not found, look for any isolated number with decimal places
      final isolatedNumberPattern = RegExp(r'(\d+\.\d+)');
      final isolatedMatches = isolatedNumberPattern.allMatches(recognizedText.text);
      if (isolatedMatches.isNotEmpty) {
        final value = isolatedMatches.first.group(1);
        if (value != null) {
          return '$value g';
        }
      }

      return 'No weight value detected';
    } catch (e) {
      log('Error extracting weight: ${e.toString()}');
      return 'Error: ${e.toString()}';
    }
  }
}
