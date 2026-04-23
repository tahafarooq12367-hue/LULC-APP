import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Change this to your machine's IP when running on a physical device.
  // Use 10.0.2.2 for Android emulator, or your LAN IP for real device.
  // Android emulator  → 10.0.2.2:5000
  // Physical device   → use the LAN IP shown when backend starts (e.g. 192.168.100.7)
  static const String _baseUrl = 'http://192.168.100.7:5000';

  /// Sends [imagePath] to the Flask backend and returns the classification result.
  static Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    final uri = Uri.parse('$_baseUrl/classify');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('image', imagePath),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': body['message'] ?? 'Server error ${response.statusCode}',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Cannot connect to server. Make sure the backend is running.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetches previous classification results from the backend.
  static Future<List<Map<String, dynamic>>> getPreviousResults() async {
    final uri = Uri.parse('$_baseUrl/history');
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final results = body['results'] as List<dynamic>? ?? [];
        return results.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Saves a result to the backend (extend as needed).
  static Future<bool> saveResult(Map<String, dynamic> result) async {
    // Results are saved to Firebase Firestore from the Flutter side.
    // This stub is kept for API compatibility.
    return true;
  }
}
