import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

import '../models/user.dart' as app_models; // ⬅️ ADD PREFIX

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔐 Attempting DIRECT BACKEND authentication...');
      print('📧 Email: $email');

      // SKIP FIREBASE AUTH - go directly to your backend
      final response = await ApiService.loginUser(
        email: email,
        password: password,
      );

      print('📥 Backend response received');
      print('✅ Response success: ${response['success']}');

      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        print('✅ Backend login successful');
        print('👤 User email: ${_user?.email}');
        print('📱 User phone: ${_user?.phone}');
        print('🏠 User address: ${_user?.address}');
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
      notifyListeners();
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
    notifyListeners();

    try {
      // COMPREHENSIVE LOGGING OF ALL INPUTS
      print('🔍 AUTH PROVIDER DEBUG - All registration inputs:');
      print('   👤 First Name: "$firstName" (length: ${firstName.length})');
      print('   👤 Last Name: "$lastName" (length: ${lastName.length})');
      print('   📧 Email: "$email" (length: ${email.length})');
      print('   🔐 Password: "${password.length} characters"');
      print('   📱 Phone: "$phone" (length: ${phone.length})');
      print('   🏠 Address: "$address" (length: ${address.length})');

      // Validate that we have all required fields
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
        phone: phone, // Use user input
        address: address, // Use user input
      );

      // ADD RESPONSE LOGGING
      print('🔍 AUTH PROVIDER DEBUG - API Response:');
      print('   Success: ${response['success']}');
      print('   Message: ${response['message']}');
      if (response['user'] != null) {
        print('   User Phone: ${response['user']['phone']}');
        print('   User Address: ${response['user']['address']}');
      }

      if (response['success'] == true) {
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
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
