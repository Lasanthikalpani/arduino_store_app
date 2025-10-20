// lib/services/api_service.dart - COMPLETE FIXED VERSION
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3001';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Helper method to get auth headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Store token after login/register
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
    return token != null && token.isNotEmpty;
  }

  // Get current user ID
  static Future<String?> getCurrentUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  // HEALTH CHECK
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final url = Uri.parse('$baseUrl/api/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      final bool success = response.statusCode == 200;
      
      return {
        'success': success,
        'status': response.statusCode,
        'message': response.body,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // LOGIN METHOD
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');

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

        final bool success = responseData['success'] == true;
        
        if (success) {
          final String? token = responseData['token'];
          final Map<String, dynamic> userData = responseData['user'] ?? {};

          final user = User.fromJson(userData);

          if (token != null) {
            await _storeAuthData(token, user.userId);
            print('✅ JWT Token stored successfully for user: ${user.userId}');
          }

          return {
            'success': true,
            'message': responseData['message'] ?? 'Login successful',
            'user': user,
          };
        } else {
          return {
            'success': false,
            'error': responseData['error'] ?? 'Login failed',
          };
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Login failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // REGISTRATION METHOD
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/register');

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

      final bool isSuccessStatus = response.statusCode == 200 || response.statusCode == 201;
      final bool isSuccessResponse = responseData['success'] == true;
      
      if (isSuccessStatus && isSuccessResponse) {
        final user = User.fromJson(responseData['user'] ?? responseData);

        if (responseData['token'] != null) {
          await _storeAuthData(responseData['token'], user.userId);
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Registration successful',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Registration failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // PRODUCTS ENDPOINTS
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final url = Uri.parse('$baseUrl/api/products');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      print('🛍️ Get Products Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        final bool success = responseData['success'] == true;
        
        if (success) {
          return {
            'success': true,
            'products': responseData['data'] ?? [],
          };
        } else {
          return {
            'success': false,
            'error': responseData['error'] ?? 'Failed to fetch products',
          };
        }
      } else {
        return {'success': false, 'error': 'Failed to fetch products'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // CATEGORIES ENDPOINTS
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final url = Uri.parse('$baseUrl/api/categories');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      print('📁 Get Categories Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        final bool success = responseData['success'] == true;
        
        if (success) {
          return {
            'success': true,
            'categories': responseData['data'] ?? [],
          };
        } else {
          return {
            'success': false,
            'error': responseData['error'] ?? 'Failed to fetch categories',
          };
        }
      } else {
        return {'success': false, 'error': 'Failed to fetch categories'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // CART ENDPOINTS
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final url = Uri.parse('$baseUrl/api/cart');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      print('🛒 Get Cart Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        final bool success = responseData['success'] == true;
        
        if (success) {
          return {
            'success': true,
            'cart': responseData['data'] ?? responseData,
          };
        } else {
          return {
            'success': false,
            'error': responseData['error'] ?? 'Failed to fetch cart',
          };
        }
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
      final url = Uri.parse('$baseUrl/api/cart/add-item');
      final response = await http
          .post(
            url,
            headers: await _getAuthHeaders(),
            body: json.encode({'productId': productId, 'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 10));

      print('➕ Add to Cart Response: ${response.statusCode}');

      final responseData = json.decode(response.body);
      
      final bool isSuccessStatus = response.statusCode == 200 || response.statusCode == 201;
      
      if (isSuccessStatus) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Item added to cart',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to add item to cart',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCartItem(
    String productId,
    int quantity,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/cart/update-item');
      final response = await http
          .put(
            url,
            headers: await _getAuthHeaders(),
            body: json.encode({'productId': productId, 'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 10));

      print('✏️ Update Cart Response: ${response.statusCode}');

      final responseData = json.decode(response.body);
      
      final bool isSuccessStatus = response.statusCode == 200;
      
      if (isSuccessStatus) {
        return {
          'success': true,
          'message': 'Cart updated successfully',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to update cart',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(String productId) async {
    try {
      final url = Uri.parse('$baseUrl/api/cart/remove-item');
      final response = await http
          .delete(
            url,
            headers: await _getAuthHeaders(),
            body: json.encode({'productId': productId}),
          )
          .timeout(const Duration(seconds: 10));

      print('🗑️ Remove from Cart Response: ${response.statusCode}');

      final responseData = json.decode(response.body);
      
      final bool isSuccessStatus = response.statusCode == 200;
      
      if (isSuccessStatus) {
        return {
          'success': true,
          'message': 'Item removed from cart',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to remove item from cart',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final url = Uri.parse('$baseUrl/api/cart/clear');
      final response = await http
          .delete(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      print('🧹 Clear Cart Response: ${response.statusCode}');

      final responseData = json.decode(response.body);
      
      final bool isSuccessStatus = response.statusCode == 200;
      
      if (isSuccessStatus) {
        return {
          'success': true,
          'message': 'Cart cleared successfully',
          'cart': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to clear cart',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ORDERS ENDPOINTS
  static Future<Map<String, dynamic>> createOrder({
    required String shippingAddress,
    required String paymentMethod,
    String? city,
    String? zipCode,
    double? totalAmount,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/orders');

      final cartResponse = await getCart();
      
      final bool isCartSuccess = cartResponse['success'] == true;
      
      if (!isCartSuccess) {
        return {'success': false, 'error': 'Failed to get cart data'};
      }

      final orderData = {
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'city': city ?? '',
        'zipCode': zipCode ?? '',
        'totalAmount': totalAmount ?? cartResponse['cart']['total'] ?? 0,
      };

      print('📦 Creating order at: $url');

      final response = await http
          .post(
            url,
            headers: await _getAuthHeaders(),
            body: json.encode(orderData),
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Order creation response: ${response.statusCode}');

      final responseData = json.decode(response.body);
      
      final bool isSuccessStatus = response.statusCode == 200 || response.statusCode == 201;
      
      if (isSuccessStatus) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Order created successfully',
          'order': responseData['data'] ?? responseData,
        };
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      print('❌ Order creation error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ✅ ADD THE MISSING METHOD HERE
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
      final url = Uri.parse('$baseUrl/api/orders');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      print('📋 Get Orders Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        final bool success = responseData['success'] == true;
        
        if (success) {
          return {
            'success': true,
            'orders': responseData['data'] ?? [],
          };
        } else {
          return {
            'success': false,
            'error': responseData['error'] ?? 'Failed to fetch orders',
          };
        }
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
      final url = Uri.parse('$baseUrl/api/auth/me');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 10));

      print('👤 Get Profile Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        final bool success = responseData['success'] == true;
        
        if (success) {
          return {
            'success': true,
            'user': responseData['data']?['user'] ?? responseData['data'] ?? responseData,
          };
        } else {
          return {
            'success': false,
            'error': responseData['error'] ?? 'Failed to fetch user profile',
          };
        }
      } else {
        return {'success': false, 'error': 'Failed to fetch user profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // ENDPOINT DISCOVERY
  static Future<void> discoverEndpoints() async {
    print('🔍 Discovering available endpoints...');

    final endpoints = [
      '/api/health',
      '/api/auth/login',
      '/api/auth/register',
      '/api/products',
      '/api/categories',
      '/api/cart',
      '/api/orders',
      '/api/auth/me',
    ];

    for (final endpoint in endpoints) {
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final response = await http.get(url).timeout(const Duration(seconds: 3));
        print('   $endpoint: ${response.statusCode}');
      } catch (e) {
        print('   $endpoint: ERROR - $e');
      }
    }
  }
}
