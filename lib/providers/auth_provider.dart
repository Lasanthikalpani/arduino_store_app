import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/user.dart' as app_models;

class AuthProvider with ChangeNotifier {
  app_models.User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false; // Add this flag

  app_models.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Safe notify listeners method
  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    safeNotifyListeners();

    try {
      print('🔐 Attempting DIRECT BACKEND authentication...');
      print('📧 Email: $email');

      final response = await ApiService.loginUser(
        email: email,
        password: password,
      );

      print('📥 Backend response received');
      print('✅ Response success: ${response['success']}');
      print('🔍 Response keys: ${response.keys}');

      if (response['success'] == true) {
        final userData = response['user'];

        if (userData is app_models.User) {
          _user = userData;
          print('✅ User object received directly');
        } else if (userData is Map<String, dynamic>) {
          _user = app_models.User.fromJson(userData);
          print('✅ User parsed from Map');
        } else {
          throw Exception('Invalid user data type: ${userData.runtimeType}');
        }

        print('✅ Backend login successful');
        print('👤 User details:');
        print('   - User ID: ${_user?.userId}');
        print('   - Name: ${_user?.fullName}');
        print('   - Email: ${_user?.email}');
        print('   - Phone: ${_user?.phone}');
        print('   - Address: ${_user?.address}');
        print('   - Role: ${_user?.role}');

        return true;
      } else {
        _error = response['error'] ?? 'Login failed';
        print('❌ Backend error: $_error');
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      print('❌ Error type: ${e.runtimeType}');
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      safeNotifyListeners(); // Use safe method
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    _error = null;
    safeNotifyListeners();

    try {
      print('🔍 AUTH PROVIDER DEBUG - All registration inputs:');
      print('   👤 First Name: "$firstName" (length: ${firstName.length})');
      print('   👤 Last Name: "$lastName" (length: ${lastName.length})');
      print('   📧 Email: "$email" (length: ${email.length})');
      print('   🔐 Password: "${password.length} characters"');
      print('   📱 Phone: "$phone" (length: ${phone.length})');
      print('   🏠 Address: "$address" (length: ${address.length})');

      if (phone.isEmpty || address.isEmpty) {
        print('❌ AUTH PROVIDER DEBUG - Missing required fields!');
        print('   Phone empty: ${phone.isEmpty}');
        print('   Address empty: ${address.isEmpty}');
        _error = 'Phone and address are required';
        return false;
      }

      final response = await ApiService.registerUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );

      print('🔍 AUTH PROVIDER DEBUG - API Response:');
      print('   Success: ${response['success']}');
      print('   Message: ${response['message']}');
      if (response['user'] != null) {
        print('   User Phone: ${response['user']['phone']}');
        print('   User Address: ${response['user']['address']}');
      }

      if (response['success'] == true) {
        if (response['user'] != null) {
          _user = app_models.User.fromJson(response['user']);
        }
        _error = null;
        return true;
      } else {
        _error = response['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      print('❌ AUTH PROVIDER DEBUG - Error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      safeNotifyListeners(); // Use safe method
    }
  }

  void logout() {
    _user = null;
    _error = null;
    safeNotifyListeners(); // Use safe method
  }

  void clearError() {
    _error = null;
    safeNotifyListeners(); // Use safe method
  }

  Future<void> initialize() async {
    _isLoading = true;
    safeNotifyListeners();

    try {
      if (await ApiService.isLoggedIn()) {
        final result = await ApiService.getUserProfile();
        if (result['success']) {
          _user = app_models.User.fromJson(result['user']);
        }
      }
    } catch (e) {
      print('❌ Initialization error: $e');
    } finally {
      _isLoading = false;
      safeNotifyListeners(); // Use safe method
    }
  }
}