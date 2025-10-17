import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Test variables
  bool _isTesting = false;
  String _testResult = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _testBackendConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = '🔌 Testing backend connection...\n';
      _testResult += '🌐 Using URL: ${ApiService.baseUrl}\n';
    });

    try {
      final url = Uri.parse('${ApiService.baseUrl}/auth');
      _testResult += '📡 Testing: $url\n';

      final response = await http.get(url).timeout(const Duration(seconds: 3));

      setState(() {
        _isTesting = false;
        _testResult += '✅ Backend is responding!\n';
        _testResult += '📥 Status: ${response.statusCode}\n';
        _testResult += '📥 Response: ${response.body}\n';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult += '❌ Cannot connect to backend!\n';
        _testResult += '💡 Make sure:\n';
        _testResult += '   1. Backend is running: npm start\n';
        _testResult += '   2. Port 3001 is available\n';
        _testResult += '   3. No firewall blocking\n';
        _testResult +=
            '   4. Test in browser: http://localhost:3001/api/auth\n';
        _testResult += '\n🔄 Error: $e\n';
      });
    }
  }

  Future<void> _performRegistration() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 🎯 USE USER INPUTS INSTEAD OF HARDCODED VALUES
      print('🎯 Starting registration with USER INPUTS:');
      print('   📱 Phone: "${_phoneController.text}"');
      print('   🏠 Address: "${_addressController.text}"');
      print('   👤 First Name: "${_firstNameController.text}"');
      print('   👤 Last Name: "${_lastNameController.text}"');
      print('   📧 Email: "${_emailController.text}"');
      print('   🔐 Password: "${_passwordController.text.length} characters"');

      final success = await authProvider.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(), // ✅ USE USER INPUT
        address: _addressController.text.trim(), // ✅ USE USER INPUT
      );

      print('🎯 Registration completed - Success: $success');

      if (success && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text('Registration completed successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text('Error: ${authProvider.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('🎯 Registration error: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Exception: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _testRegistration() async {
    setState(() {
      _isTesting = true;
      _testResult = '🔄 Starting registration test...\n';
    });

    try {
      // Test data - use unique email each time
      final testEmail =
          'test${DateTime.now().millisecondsSinceEpoch}@example.com';

      _testResult += '📧 Using email: $testEmail\n';

      final response = await ApiService.registerUser(
        firstName: 'Test',
        lastName: 'User',
        email: testEmail,
        password: 'password123',
        phone: '+1234567890',
        address: '123 Test Street',
      );

      setState(() {
        _isTesting = false;
        if (response['success'] == true) {
          _testResult += '✅ REGISTRATION SUCCESS!\n';
          _testResult += '📝 Message: ${response['message']}\n';
          _testResult += '🆔 User ID: ${response['user']?['userId']}\n';
          _testResult += '🎯 Role: ${response['user']?['role']}\n';
          _testResult +=
              '📛 Name: ${response['user']?['firstName']} ${response['user']?['lastName']}\n';
          _testResult += '📱 Phone: ${response['user']?['phone']}\n';
          _testResult += '🏠 Address: ${response['user']?['address']}\n';
        } else {
          _testResult += '❌ REGISTRATION FAILED!\n';
          _testResult += '📝 Error: ${response['message']}\n';
        }
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult += '💥 EXCEPTION: $e\n';
      });
    }
  }

  void _clearTestResult() {
    setState(() {
      _testResult = '';
    });
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino Store - Register'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Test Section
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔧 Backend Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Test Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isTesting
                                    ? null
                                    : _testBackendConnection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Test Connection'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isTesting
                                    ? null
                                    : _testRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Test Registration'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Test Hardcoded Registration Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _performRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Test Hardcoded Registration'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Test Results
                        if (_testResult.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Test Results:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: _clearTestResult,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _testResult,
                                  style: const TextStyle(
                                    fontFamily: 'Monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_isTesting)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Logo/Header
                const Icon(Icons.shopping_cart, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // First Name Field
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name Field
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Error Message from AuthProvider
                if (authProvider.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => authProvider.clearError(),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              // Show debug dialog first
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Registration'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'You are about to register with:',
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '📱 Phone: "${_phoneController.text.trim()}"',
                                        ),
                                        Text(
                                          '🏠 Address: "${_addressController.text.trim()}"',
                                        ),
                                        Text(
                                          '👤 Name: "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}"',
                                        ),
                                        Text(
                                          '📧 Email: "${_emailController.text.trim()}"',
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Click Register to continue.',
                                        ), // ✅ Updated message
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _performRegistration();
                                        },
                                        child: const Text('Register'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
