import 'dart:developer';

import 'package:app/pages/scan_sample.dart';
import 'package:app/shared/api_methods.dart';

import 'package:app/widgets/helper_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScanDataProvider {
  static final ScanDataProvider _instance = ScanDataProvider._internal();

  factory ScanDataProvider() {
    return _instance;
  }

  ScanDataProvider._internal();

  String sampleId = '';
  String weight = '';

  bool get hasCompleteScanData => sampleId.isNotEmpty && weight.isNotEmpty;

  void clearData() {
    sampleId = '';
    weight = '';
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScanDataProvider _dataProvider = ScanDataProvider();
  final APIServices _apiServices = APIServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Odoo Weight Tracker'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _dataProvider.clearData();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Scan data cleared')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showApiSettingsDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status cards showing current data
              if (_dataProvider.sampleId.isNotEmpty ||
                  _dataProvider.weight.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Current Scan Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            _dataProvider.sampleId.isNotEmpty
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _dataProvider.sampleId.isNotEmpty
                                ? Colors.green
                                : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sample ID: ${_dataProvider.sampleId.isNotEmpty ? _dataProvider.sampleId : "Not scanned"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _dataProvider.weight.isNotEmpty
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _dataProvider.weight.isNotEmpty
                                ? Colors.green
                                : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Weight: ${_dataProvider.weight.isNotEmpty ? _dataProvider.weight : "Not scanned"}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 32),

              // Main buttons as required
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ScanScreen(scanType: 'sample')),
                  );
                  setState(() {});
                },
                child: Container(
                  width: 200,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Scan Sample')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ScanScreen(scanType: 'weight')),
                  );
                  setState(() {});
                },
                child: Container(
                  width: 200,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Scan Weight')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              SizedBox(height: 32),

              if (_dataProvider.hasCompleteScanData)
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // First validate API settings
                      final isValid =
                          await _apiServices.validateCurrentApiSettings();
                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Please configure API settings first')),
                        );
                        return;
                      }

                      // Send data using the API service
                      await _apiServices.sendWeightData(
                        context: context,
                        sampleCode: _dataProvider.sampleId,
                        weight: _dataProvider.weight,
                      );

                      setState(() {
                        _dataProvider.clearData();
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: Icon(Icons.send),
                  label: Text('Submit Complete Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showApiSettingsDialog(BuildContext context) async {
    final settings = await _apiServices.getCurrentApiSettings();
    final apiTokenController =
        TextEditingController(text: settings['apiToken'] ?? '');
    final dbNameController =
        TextEditingController(text: settings['dbName'] ?? '');
    final loginController =
        TextEditingController(text: settings['login'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('API Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dbNameController,
              decoration: InputDecoration(labelText: 'Database Name'),
            ),
            TextField(
              controller: apiTokenController,
              decoration: InputDecoration(labelText: 'API Token'),
              obscureText: true,
            ),
            TextField(
              controller: loginController,
              decoration: InputDecoration(labelText: 'Login'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final result = await _apiServices.configureApiSettings(
                  apiToken: apiTokenController.text,
                  dbName: dbNameController.text,
                  login: loginController.text,
                );

                if (result == 'SUCCESS') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings saved successfully')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving settings: $result')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}
