import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<bool> login(String email, String password) async {
    try {
      var response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> register(String email, String password, String name) async {
    try {
      var response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password, 'full_name': name}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, double>?> getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      return {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyzeImage(File imageFile) async {
    try {
      final token = await getToken();
      // Eğer token varsa korumalı rotaya at, yoksa eski rotaya at
      final url = token != null ? '$_baseUrl/user/analyze-authenticated' : '$_baseUrl/analyze';
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['lang'] = 'tr';

      // Konum varsa ekle
      final loc = await getLocation();
      if (token != null && loc != null) {
        request.fields['lat'] = loc['lat'].toString();
        request.fields['lng'] = loc['lng'].toString();
      }

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        // Authenticated endpoint "status" ve "data" dönüyor
        var jsonRes = json.decode(responseData.body);
        if (jsonRes.containsKey('data')) {
            return jsonRes['data'];
        }
        return jsonRes;
      } else {
        print("API Hatası: ${response.statusCode} - ${responseData.body}");
        return null;
      }
    } catch (e) {
      print("API İsteği başarısız oldu: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getHistory() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      var response = await http.get(
        Uri.parse('$_baseUrl/user/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print("History fetch error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getVisitedPlaces() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      var response = await http.get(
        Uri.parse('$_baseUrl/user/visited-places'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      print('VisitedPlaces fetch error: $e');
      return [];
    }
  }
}
