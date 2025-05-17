import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _sampleIdKey = 'sample_id';
  static const String _weightKey = 'weight';

  static Future<void> saveSampleId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sampleIdKey, id);
  }

  static Future<void> saveWeight(String weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightKey, weight);
  }

  static Future<String?> getSampleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sampleIdKey);
  }

  static Future<String?> getWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weightKey);
  }

  static Future<Map<String, String?>> getPayload() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'sample_id': prefs.getString(_sampleIdKey),
      'weight': prefs.getString(_weightKey),
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sampleIdKey);
    await prefs.remove(_weightKey);
  }

  static const String _tokenKey = 'token';
  static const _userKey = 'user';

  static Future<void> saveTokenId(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String> getTokenId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) ?? "";
  }

  static Future<void> saveServerSettings(String url, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url');
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
