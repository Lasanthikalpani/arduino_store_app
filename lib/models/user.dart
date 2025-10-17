class User {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isActive;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      isActive: json['isActive'] ?? true,
    );
  }

  String get fullName => '$firstName $lastName';
}