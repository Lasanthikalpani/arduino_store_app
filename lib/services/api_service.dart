// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart'; // ADD THIS IMPORT

class ApiService {
  static const String baseUrl = 'http://localhost:3001/api';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Helper method to get auth headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Store token after login/register - FIXED METHOD
  static Future<void> _storeAuthData(String token, String userId) async {
    await _secureStorage.write(key: 'auth_token', value: token);
    await _secureStorage.write(key: 'user_id', value: userId);
  }

  // Clear token on logout
  static Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_id');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null;
  }

  // Enhanced login method - FIXED
  // lib/services/api_service.dart - FIXED loginUser method
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');

      print('🚀 Logging in user: $email');

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

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print('🔍 Response data structure:');
        print('   - success: ${responseData['success']}');
        print('   - message: ${responseData['message']}');
        print(
          '   - token: ${responseData['token'] != null ? "PRESENT" : "MISSING"}',
        );
        print(
          '   - user: ${responseData['user'] != null ? "PRESENT" : "MISSING"}',
        );
        print('   - userId: ${responseData['userId']}');

        // Extract token
        final String? token = responseData['token'];

        // Extract user data - handle different possible structures
        Map<String, dynamic> userData;

        if (responseData['user'] != null) {
          userData = responseData['user'] as Map<String, dynamic>;
        } else {
          // If no 'user' field, use the main response but remove non-user fields
          userData = Map.from(responseData);
          userData.remove('success');
          userData.remove('message');
          userData.remove('token');
        }

        // Ensure userId is set correctly
        if (userData['userId'] == null && responseData['userId'] != null) {
          userData['userId'] = responseData['userId'];
        }

        print('🔍 Final user data for User.fromJson(): $userData');

        // Create User object from response
        final user = User.fromJson(userData);

        // Store authentication data
        if (token != null) {
          await _storeAuthData(token, user.userId);
          print('✅ JWT Token stored successfully for user: ${user.userId}');
        }

        // Return Map with User object
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'user': user, // This is a User object, not a Map
        };
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Add this method to your ApiService for health checking
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      return {
        'success': response.statusCode == 200,
        'status': response.statusCode,
        'message': response.body,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Your existing registration method (enhanced) - FIXED
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

      print('🚀 Registering user: $email');

      final Map<String, dynamic> requestBody = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
      };

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Create User object from response
        final user = User.fromJson(responseData['user'] ?? responseData);

        // Store token if available - FIXED
        if (responseData['token'] != null) {
          await _storeAuthData(responseData['token'], user.userId);
        } else if (responseData['user']?['token'] != null) {
          await _storeAuthData(responseData['user']['token'], user.userId);
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Registration successful',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // PRODUCTS ENDPOINTS
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final url = Uri.parse('$baseUrl/products');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'products': responseData['data'] ?? responseData,
        };
      } else {
        return {'success': false, 'error': 'Failed to fetch products'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // CART ENDPOINTS
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final url = Uri.parse('$baseUrl/cart');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'cart': responseData['data'] ?? responseData};
      } else {
        return {'success': false, 'error': 'Failed to fetch cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addToCart(
    String productId,
    int quantity,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/cart/items');
      final response = await http
          .post(
            url,
            headers: await _getAuthHeaders(),
            body: json.encode({'productId': productId, 'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Item added to cart',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {'success': false, 'error': 'Failed to add item to cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCartItem(
    String itemId,
    int quantity,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/cart/items/$itemId');
      final response = await http
          .put(
            url,
            headers: await _getAuthHeaders(),
            body: json.encode({'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Cart updated successfully',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {'success': false, 'error': 'Failed to update cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(String itemId) async {
    try {
      final url = Uri.parse('$baseUrl/cart/items/$itemId');
      final response = await http
          .delete(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Item removed from cart',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {'success': false, 'error': 'Failed to remove item from cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ORDERS ENDPOINTS
  // In ApiService, update the createOrder method:
  // In lib/services/api_service.dart - UPDATE createOrder method:

  // In lib/services/api_service.dart - FIX the null safety issue:

  static Future<Map<String, dynamic>> createOrder({
    required String shippingAddress,
    required String city,
    required String zipCode,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    try {
      // Try different order endpoint variations
      final List<String> possibleEndpoints = [
        '$baseUrl/orders',
        '$baseUrl/order',
        '$baseUrl/checkout/order',
      ];

      Map<String, dynamic>? lastResponse;
      String? lastError;

      for (final endpoint in possibleEndpoints) {
        try {
          final url = Uri.parse(endpoint);

          // Get cart first to include items in order
          final cartResponse = await getCart();
          if (cartResponse['success'] != true) {
            return {'success': false, 'error': 'Failed to get cart data'};
          }

          final orderData = {
            'shippingAddress': shippingAddress,
            'city': city,
            'zipCode': zipCode,
            'paymentMethod': paymentMethod,
            'totalAmount': totalAmount,
            'items': cartResponse['cart']['items'],
            'status': 'pending',
          };

          print('📦 Creating order at: $endpoint');
          print('📦 Order data: $orderData');

          final response = await http
              .post(
                url,
                headers: await _getAuthHeaders(),
                body: json.encode(orderData),
              )
              .timeout(const Duration(seconds: 10));

          print('📥 Order creation response: ${response.statusCode}');
          print('📥 Order creation body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final responseData = json.decode(response.body);
            return {
              'success': true,
              'message':
                  responseData['message'] ?? 'Order created successfully',
              'order': responseData['data'] ?? responseData,
            };
          } else {
            lastResponse = json.decode(response.body);
            // FIX: Use null-safe access
            lastError = lastResponse?['error'] ?? 'Failed to create order';
            print('❌ Endpoint $endpoint failed: $lastError');
          }
        } catch (e) {
          lastError = 'Endpoint $endpoint error: $e';
          print('❌ $lastError');
        }
      }

      // If all endpoints failed
      return {
        'success': false,
        'error': lastError ?? 'All order endpoints failed',
      };
    } catch (e) {
      print('❌ Order creation error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  // In lib/services/api_service.dart - ADD this method:

  static Future<void> discoverEndpoints() async {
    print('🔍 Discovering available endpoints...');

    final endpoints = [
      '/orders',
      '/order',
      '/checkout',
      '/checkout/order',
      '/api/orders',
      '/api/order',
    ];

    for (final endpoint in endpoints) {
      try {
        final url = Uri.parse('http://localhost:3001$endpoint');
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: 3));
        print('   $endpoint: ${response.statusCode}');
      } catch (e) {
        print('   $endpoint: ERROR - $e');
      }
    }
  }

  // TEMPORARY: Add mock order creation for testing
  // In lib/services/api_service.dart - ADD this mock order method:

  // Add this method to your ApiService class
  static Future<Map<String, dynamic>> createOrderMock({
    required String shippingAddress,
    required String city,
    required String zipCode,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock order data
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'success': true,
      'message': 'Order created successfully!',
      'order': {
        'id': orderId,
        'orderNumber': 'ORD-${orderId.substring(orderId.length - 6)}',
        'status': 'confirmed',
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'city': city,
        'zipCode': zipCode,
        'paymentMethod': paymentMethod,
        'items': [],
        'createdAt': DateTime.now().toIso8601String(),
        'estimatedDelivery': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      },
    };
  }

  static Future<Map<String, dynamic>> getOrders() async {
    try {
      final url = Uri.parse('$baseUrl/orders');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'orders': responseData['data'] ?? responseData,
        };
      } else {
        return {'success': false, 'error': 'Failed to fetch orders'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // USER PROFILE ENDPOINTS
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final url = Uri.parse('$baseUrl/auth/profile');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'user': responseData['data'] ?? responseData};
      } else {
        return {'success': false, 'error': 'Failed to fetch user profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
