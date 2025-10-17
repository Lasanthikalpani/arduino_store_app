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
      print('🔐 Attempting Firebase authentication...');

      // 1. Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // 2. Get the ID token - PROPER NULL SAFETY
      final user = userCredential.user;
      if (user == null) {
        _error = 'User not found after authentication';
        return false;
      }

      final idToken = await user.getIdToken();

      // Check if idToken is null or empty
      if (idToken == null || idToken.isEmpty) {
        _error = 'Failed to get authentication token';
        return false;
      }

      print('✅ Firebase authentication successful');
      print('📝 ID token received: ${idToken.substring(0, 20)}...');

      // 3. Call your backend with the token (idToken is now guaranteed non-null)
      final response = await ApiService.loginUser(idToken: idToken);

      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        print('✅ Backend login successful');
        return true;
      } else {
        _error = response['error'] ?? 'Login failed';
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase auth error: ${e.code} - ${e.message}');

      if (e.code == 'user-not-found') {
        _error = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        _error = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        _error = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        _error = 'This account has been disabled';
      } else if (e.code == 'too-many-requests') {
        _error = 'Too many attempts. Please try again later.';
      } else {
        _error = 'Login failed: ${e.message}';
      }
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      _error = 'Login failed: $e';
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
