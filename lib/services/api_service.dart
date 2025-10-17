// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api';

  // Test with simple endpoint first
  static Future<Map<String, dynamic>> testSimpleRegistration({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/simple-test');

      final Map<String, dynamic> requestBody = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

      print('🚀 Testing SIMPLE endpoint: $url');
      print('📦 Request body: $requestBody');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Test successful',
          'user': responseData['user'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Test failed',
        };
      }
    } catch (e) {
      print('❌ Simple test error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Real registration (for when Firebase is fixed)
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');

      // ADD DETAILED LOGGING
      print('🚀 API SERVICE DEBUG - Preparing request:');
      print('   📱 Phone: "$phone" (type: ${phone.runtimeType})');
      print('   🏠 Address: "$address" (type: ${address.runtimeType})');
      print('   👤 First Name: "$firstName"');
      print('   👤 Last Name: "$lastName"');
      print('   📧 Email: "$email"');

      final Map<String, dynamic> requestBody = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
      };

      print('📦 API SERVICE DEBUG - Request body:');
      print('   $requestBody');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 API SERVICE DEBUG - Response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Registration successful',
          'user': responseData['user'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ API SERVICE DEBUG - Error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
  // Add this below registerUser()

  // In api_service.dart - UPDATE the loginUser method
  static Future<Map<String, dynamic>> loginUser({
    required String idToken, // ⬅️ CHANGE from email/password to idToken
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      final Map<String, dynamic> requestBody = {
        'idToken': idToken, // ⬅️ SEND token instead of email/password
      };

      print('🚀 Sending LOGIN request to backend with token');
      print('📦 Request body: {idToken: ***}'); // Don't log actual token

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login API error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // KEEP the old method for backward compatibility or DELETE it
  static Future<Map<String, dynamic>> loginUserOld({
    required String email,
    required String password,
  }) async {
    // This is your OLD method - you can delete it
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'data': responseData['user'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Invalid credentials',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
