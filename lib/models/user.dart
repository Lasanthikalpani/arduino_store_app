class User {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;      // Add this
  final String address;    // Add this
  final String role;
  final bool isActive;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,   // Add this
    required this.address, // Add this
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? json['uid'] ?? '', // Support both 'userId' and 'uid'
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',      // Add this
      address: json['address'] ?? '',  // Add this
      role: json['role'] ?? 'customer',
      isActive: json['isActive'] ?? true,
    );
  }

  String get fullName => '$firstName $lastName';
}