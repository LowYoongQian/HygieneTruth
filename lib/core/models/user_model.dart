enum UserRole { user, admin, government, owner }

enum AccountStatus { active, suspended, pendingVerification, deactivated }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final AccountStatus status;
  final String avatarUrl;
  final String? gender;
  final String? country;
  final String? state;
  final String? joinedDate;
  final String? memberTier;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.avatarUrl,
    this.gender,
    this.country,
    this.state,
    this.joinedDate,
    this.memberTier,
  });
}
