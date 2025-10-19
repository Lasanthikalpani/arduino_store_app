import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildDebugSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDebugInfo(
    String label,
    String value, {
    bool isSuccess = true,
    bool isTesting = false,
  }) {
    Color textColor = Colors.black;
    if (isTesting)
      textColor = Colors.blue;
    else if (!isSuccess)
      textColor = Colors.red;
    else if (value.contains('✅'))
      textColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: isTesting ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _testApiConnection() async {
    try {
      print('🔧 Testing API connection to backend...');

      // Test a real endpoint that definitely exists
      final productsUrl = Uri.parse('http://localhost:3001/api/products');
      final response = await http
          .get(productsUrl)
          .timeout(const Duration(seconds: 5));

      print('🔧 Products endpoint: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {
          'reachable': true,
          'details': 'API is fully operational (Products endpoint working)',
        };
      } else if (response.statusCode == 401) {
        return {
          'reachable': true,
          'details': 'API is reachable but requires authentication',
        };
      } else {
        return {
          'reachable': true, // Still reachable, just different response
          'details': 'Endpoint returned HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('🔧 API connection test failed: $e');
      return {
        'reachable': false,
        'error': e.toString(),
        'details': 'Make sure backend is running on localhost:3001',
      };
    }
  }

  Future<Map<String, dynamic>> _testAuthentication(
    String email,
    String password,
  ) async {
    try {
      print('🔧 Testing authentication with current credentials...');

      final url = Uri.parse('http://localhost:3001/api/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      print('🔧 Auth test response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'user': responseData['userId'] ?? 'Unknown',
          'token': responseData['token'],
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'error': responseData['error'] ?? 'HTTP ${response.statusCode}',
          'message': responseData['message'],
        };
      }
    } catch (e) {
      print('🔧 Authentication test failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _performLoginWithLogging(
    BuildContext context,
    AuthProvider authProvider,
    String email,
    String password,
  ) async {
    print('🎯 Starting login process with detailed logging...');
    print('📧 Email: $email');
    print('🔐 Password: ${password.length} characters');

    // Clear any previous errors
    authProvider.clearError();

    final success = await authProvider.login(email, password);

    // Use post-frame callback to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Login successful! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          print('🎉 Login successful - automatic redirect should happen');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Login failed: ${authProvider.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          print('💥 Login failed: ${authProvider.error}');

          // Show detailed error dialog
          _showErrorDetails(context, authProvider.error ?? 'Unknown error');
        }
      }
    });
  }

  void _showErrorDetails(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Login Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The login failed with the following error:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: SelectableText(
                  error,
                  style: const TextStyle(fontFamily: 'Monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Check backend console for detailed logs\n'
                '• Verify email/password are correct\n'
                '• Ensure backend is running on port 3001\n'
                '• Check browser console for network errors',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog(BuildContext context, AuthProvider authProvider) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange),
                SizedBox(width: 8),
                Text('🔧 Login Debug Panel'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login Process Analysis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Input Data
                  _buildDebugSection('📝 Input Data', [
                    _buildDebugInfo('Email', email),
                    _buildDebugInfo(
                      'Password',
                      '${password.length} characters',
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // API Connection Test
                  FutureBuilder<Map<String, dynamic>>(
                    future: _testApiConnection(),
                    builder: (context, snapshot) {
                      final isTesting =
                          snapshot.connectionState == ConnectionState.waiting;
                      final hasData = snapshot.hasData;

                      return _buildDebugSection('🌐 API Connection', [
                        if (isTesting)
                          _buildDebugInfo(
                            'Status',
                            'Testing connection...',
                            isTesting: true,
                          )
                        else if (hasData)
                          _buildDebugInfo(
                            'Backend Status',
                            snapshot.data!['reachable']
                                ? '✅ ONLINE'
                                : '❌ OFFLINE',
                            isSuccess: snapshot.data!['reachable'],
                          )
                        else
                          _buildDebugInfo(
                            'Status',
                            '❌ Test failed',
                            isSuccess: false,
                          ),

                        if (hasData && snapshot.data!['details'] != null)
                          _buildDebugInfo(
                            'Details',
                            snapshot.data!['details']!,
                          ),

                        if (hasData && snapshot.data!['error'] != null)
                          _buildDebugInfo(
                            'Error',
                            snapshot.data!['error']!,
                            isSuccess: false,
                          ),
                      ]);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Authentication Test
                  FutureBuilder<Map<String, dynamic>>(
                    future: _testAuthentication(email, password),
                    builder: (context, snapshot) {
                      final isTesting =
                          snapshot.connectionState == ConnectionState.waiting;
                      final hasData = snapshot.hasData;

                      return _buildDebugSection('🔐 Authentication Test', [
                        if (isTesting)
                          _buildDebugInfo(
                            'Status',
                            'Testing login...',
                            isTesting: true,
                          )
                        else if (hasData)
                          _buildDebugInfo(
                            'Login Result',
                            snapshot.data!['success']
                                ? '✅ SUCCESS'
                                : '❌ FAILED',
                            isSuccess: snapshot.data!['success'],
                          )
                        else
                          _buildDebugInfo(
                            'Status',
                            'Not tested',
                            isTesting: false,
                          ),

                        if (hasData && snapshot.data!['message'] != null)
                          _buildDebugInfo(
                            'Message',
                            snapshot.data!['message']!,
                          ),

                        if (hasData && snapshot.data!['user'] != null)
                          _buildDebugInfo('User ID', snapshot.data!['user']!),

                        if (hasData && snapshot.data!['token'] != null)
                          _buildDebugInfo(
                            'Token',
                            '${snapshot.data!['token']!.length} chars',
                          ),

                        if (hasData && snapshot.data!['error'] != null)
                          _buildDebugInfo(
                            'Error',
                            snapshot.data!['error']!,
                            isSuccess: false,
                          ),
                      ]);
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text(
                    'Next Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• If API is online and auth works, proceed with login\n'
                    '• Check console for detailed backend logs\n'
                    '• Verify user data matches expectations',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              OutlinedButton(
                onPressed: () async {
                  // Test again
                  setState(() {});
                },
                child: const Text('Test Again'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close debug dialog
                  await _performLoginWithLogging(
                    context,
                    authProvider,
                    email,
                    password,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Proceed with Login'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performLogin(
    BuildContext context,
    AuthProvider authProvider,
    String email,
    String password,
  ) async {
    print('🎯 Starting login process...');
    print('📧 Email: $email');
    print('🔐 Password: ${password.length} characters');

    final success = await authProvider.login(email, password);

    // Use a post-frame callback to ensure context is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          print('✅ Login successful - user should be redirected automatically');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Login failed: ${authProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
          print('❌ Login failed: ${authProvider.error}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino Store - Login'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Header
              const Icon(Icons.shopping_cart, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

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
              const SizedBox(height: 20),

              // Error Message
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

              // Debug Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using direct backend authentication',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            // Show debug dialog first
                            _showDebugDialog(context, authProvider);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Register Link
              TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                child: const Text(
                  "Don't have an account? Register here",
                  style: TextStyle(color: Colors.blue),
                ),
              ),

              // Debug Section
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                'Debug Info',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Backend: ${const bool.fromEnvironment('DEBUG') ? 'Debug' : 'Production'}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
