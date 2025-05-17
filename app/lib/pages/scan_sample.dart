import 'dart:developer';
import 'dart:io';

import 'package:app/pages/home.dart';
import 'package:app/services/ocr.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanScreen extends StatefulWidget {
  final String scanType;

  ScanScreen({required this.scanType});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();
  final ScanDataProvider _dataProvider = ScanDataProvider();

  String _scannedValue = '';
  String? _imagePath;
  bool _isProcessing = false;
  bool _manualEntryMode = false;
  final TextEditingController _manualController = TextEditingController();

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _isProcessing = true;
        _imagePath = photo.path;
        _scannedValue = '';
      });

      try {
        String? result;
        if (widget.scanType == 'sample') {
          result = await _ocrService.extractQrFromImage(photo.path);
        } else {
          result = await _ocrService.extractWeightFromImage(photo.path);
        }

        setState(() {
          _scannedValue = result ?? 'Scan Failed';
          _isProcessing = false;
          
          // If scan was successful and doesn't contain error messages, pre-fill manual entry
          if (!_scannedValue.contains('No ') && 
              !_scannedValue.contains('Error') && 
              !_scannedValue.contains('detected')) {
            _manualController.text = _scannedValue;
          }
        });
      } catch (e) {
        setState(() {
          _scannedValue = 'Error: $e';
          _isProcessing = false;
        });
      }
    }
  }

  void _saveScanData() {
    String valueToSave = _manualEntryMode ? _manualController.text : _scannedValue;
    
    if (valueToSave.isNotEmpty) {
      if (widget.scanType == 'sample') {
        _dataProvider.sampleId = valueToSave;
      } else {
        _dataProvider.weight = valueToSave;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${widget.scanType.capitalize()} data saved successfully')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid ${widget.scanType}')),
      );
    }
  }

  void _toggleEntryMode() {
    setState(() {
      _manualEntryMode = !_manualEntryMode;
      if (_manualEntryMode && _scannedValue.isNotEmpty && 
          !_scannedValue.contains('No ') && 
          !_scannedValue.contains('Error')) {
        _manualController.text = _scannedValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanTitle = widget.scanType == 'sample' ? 'Sample ID' : 'Weight';
    final buttonColor =
        widget.scanType == 'sample' ? Colors.blue : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan $scanTitle'),
        backgroundColor: buttonColor,
        actions: [
          IconButton(
            icon: Icon(_manualEntryMode ? Icons.camera_alt : Icons.edit),
            onPressed: _toggleEntryMode,
            tooltip: _manualEntryMode ? 'Switch to Camera' : 'Switch to Manual Entry',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _manualEntryMode ? _buildManualEntryView() : _buildCameraView(scanTitle, buttonColor),
      ),
    );
  }

  Widget _buildCameraView(String scanTitle, Color buttonColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image preview
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.grey[300],
          child: _imagePath != null
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.file(
                      File(_imagePath!),
                      fit: BoxFit.contain,
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black38,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Text('No image captured'),
                ),
        ),
        SizedBox(height: 16),

        // Scanned value display
        if (_scannedValue.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Scanned $scanTitle:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _scannedValue,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 24),

        // Scan button
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _takePicture,
          icon: Icon(Icons.camera_alt),
          label: Text('Capture $scanTitle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        SizedBox(height: 16),

        // Save button
        if (_scannedValue.isNotEmpty &&
            !_scannedValue.contains('No ') &&
            !_scannedValue.contains('Error'))
          ElevatedButton.icon(
            onPressed: _saveScanData,
            icon: Icon(Icons.save),
            label: Text('Save $scanTitle'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildManualEntryView() {
    final scanTitle = widget.scanType == 'sample' ? 'Sample ID' : 'Weight';
    final buttonColor = widget.scanType == 'sample' ? Colors.blue : Colors.orange;
    final hintText = widget.scanType == 'sample' ? 'Enter sample ID' : 'Enter weight (e.g., 10.5 g)';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.scanType == 'sample' ? Icons.qr_code : Icons.scale,
          size: 64,
          color: buttonColor,
        ),
        SizedBox(height: 24),
        Text(
          'Manual $scanTitle Entry',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 32),
        TextField(
          controller: _manualController,
          decoration: InputDecoration(
            labelText: scanTitle,
            hintText: hintText,
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              widget.scanType == 'sample' ? Icons.qr_code : Icons.monitor_weight,
            ),
          ),
          keyboardType: widget.scanType == 'weight' 
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
        ),
        SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _manualController.text.isNotEmpty ? _saveScanData : null,
          icon: Icon(Icons.save),
          label: Text('Save $scanTitle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
