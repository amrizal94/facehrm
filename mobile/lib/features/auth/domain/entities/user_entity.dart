class UserEntity {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';
  bool get isHR => role == 'hr';
  bool get isStaff => role == 'staff';
}
