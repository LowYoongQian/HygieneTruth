enum UserRole { user, admin, government, owner }

enum AccountStatus { active, suspended, pendingVerification, deactivated }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final AccountStatus status;
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.avatarUrl,
  });
}
