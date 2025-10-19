// lib/models/user.dart - ENHANCED with better parsing
class User {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print('🔍 USER.fromJson() - Received JSON: $json');
    
    // Handle different possible field names and structures
    final userId = json['userId'] ?? json['uid'] ?? json['id'] ?? json['_id'] ?? '';
    
    // Handle phone - ensure it's a string
    final phone = (json['phone'] ?? '').toString();
    
    // Handle address - ensure it's a string
    final address = (json['address'] ?? '').toString();
    
    // Handle createdAt/updatedAt - they might be strings or objects
    String? parseDate(dynamic dateData) {
      if (dateData == null) return null;
      if (dateData is String) return dateData;
      if (dateData is Map) {
        // Handle Firestore timestamp {_seconds: xxx, _nanoseconds: xxx}
        if (dateData['_seconds'] != null) {
          final seconds = dateData['_seconds'] as int;
          final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          return date.toIso8601String();
        }
      }
      return dateData.toString();
    }
    
    print('🔍 USER.fromJson() - Parsed fields:');
    print('   userId: $userId');
    print('   phone: $phone');
    print('   address: $address');
    
    return User(
      userId: userId,
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: phone,
      address: address,
      role: (json['role'] ?? 'customer').toString(),
      isActive: json['isActive'] ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  String toString() {
    return 'User(userId: $userId, name: $fullName, email: $email, role: $role)';
  }
}