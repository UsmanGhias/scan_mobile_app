import 'dart:convert';
import 'dart:developer';

import 'package:app/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class APIServices {
  // Default endpoint for weight update
  static const String _weightEndpoint = '/api/weight/update';

  // Keys for SharedPreferences
  static const String _apiTokenKey = 'api_token';
  static const String _dbKey = 'database_name';
  static const String _loginKey = 'login';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final apiToken = prefs.getString(_apiTokenKey);
    final dbName = prefs.getString(_dbKey);
    
    if (apiToken == null || dbName == null) {
      throw Exception('API credentials not configured');
    }

    return {
      'Content-Type': 'application/json',
      'db': dbName,
      'token': apiToken,
    };
  }

  Future<void> sendWeightData({
    required BuildContext context,
    required String sampleCode,
    required String weight,
    String? customEndpoint,
  }) async {
    try {
      final headers = await _getHeaders();
      final endpoint = customEndpoint ?? _weightEndpoint;
      final url = Uri.parse(endpoint);

      final payload = jsonEncode({
        'sample_code': sampleCode,
        'weight': weight,
      });

      log("Sending to API: $payload");
      log("Headers: $headers");

      final response = await http.post(
        url,
        headers: headers,
        body: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'Success' && responseData['res'] == true) {
            showSnackbar(
                context: context, content: 'Weight data sent successfully');
          } else {
            throw Exception('API reported failure: ${responseData['status']}');
          }
        } catch (e) {
          log("Error parsing response: $e");
          showSnackbar(
              context: context, content: 'Server responded but with invalid format');
        }
      } else {
        throw Exception(
            'Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      showSnackbar(context: context, content: 'Error: $e');
      rethrow;
    }
  }

  Future<String> configureApiSettings({
    required String apiToken,
    required String dbName,
    required String login,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_apiTokenKey, apiToken);
      await prefs.setString(_dbKey, dbName);
      await prefs.setString(_loginKey, login);

      return 'SUCCESS';
    } catch (e) {
      log('Error saving API settings: $e');
      return 'Error: $e';
    }
  }

  Future<Map<String, String?>> getCurrentApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'apiToken': prefs.getString(_apiTokenKey),
      'dbName': prefs.getString(_dbKey),
      'login': prefs.getString(_loginKey),
    };
  }

  Future<bool> validateCurrentApiSettings() async {
    try {
      final settings = await getCurrentApiSettings();
      return settings['apiToken'] != null && 
             settings['dbName'] != null && 
             settings['login'] != null;
    } catch (e) {
      return false;
    }
  }
}
