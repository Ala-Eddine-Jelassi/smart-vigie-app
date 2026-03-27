class AdminUser {
  final String id;
  final String email;
  final String name;
  final DateTime lastLogin;
  final DateTime createdAt;
  final String role;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.lastLogin,
    required this.createdAt,
    required this.role,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'lastLogin': lastLogin.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'role': role,
      'isActive': isActive,
    };
  }

  factory AdminUser.fromMap(String id, Map<String, dynamic> map) {
    return AdminUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      lastLogin: DateTime.parse(map['lastLogin'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      role: map['role'] ?? 'admin',
      isActive: map['isActive'] ?? true,
    );
  }
}