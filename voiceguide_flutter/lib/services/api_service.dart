import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Geliştirme ortamı için emulator IP'si veya kendi lokal IP'nizi girin.
  // Android emulator için genellikle: 10.0.2.2
  // iOS simulator için: 127.0.0.1
  // Fiziksel cihaz için lokal ağ IP'niz (örn: 192.168.1.x)
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1/analyze';

  static Future<Map<String, dynamic>?> analyzeImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.fields['lang'] = 'tr';

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return json.decode(responseData.body);
      } else {
        print("API Hatası: ${response.statusCode} - ${responseData.body}");
        return null;
      }
    } catch (e) {
      print("API İsteği başarısız oldu: $e");
      return null;
    }
  }
}
