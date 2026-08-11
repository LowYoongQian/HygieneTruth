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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    UserRole parseRole(String? r) {
      if (r == 'businessman' || r == 'owner') return UserRole.owner;
      if (r == 'admin') return UserRole.admin;
      if (r == 'government') return UserRole.government;
      return UserRole.user;
    }

    AccountStatus parseStatus(String? s) {
      if (s == 'suspended') return AccountStatus.suspended;
      if (s == 'pending' || s == 'pendingVerification') return AccountStatus.pendingVerification;
      if (s == 'deactivated') return AccountStatus.deactivated;
      return AccountStatus.active;
    }

    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'User',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: parseRole(map['role']?.toString()),
      status: parseStatus(map['status']?.toString()),
      avatarUrl: (map['avatar_url'] != null && map['avatar_url'].toString().isNotEmpty)
          ? map['avatar_url'].toString()
          : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
      gender: map['gender']?.toString(),
      country: map['country']?.toString(),
      state: map['state']?.toString(),
      joinedDate: map['created_at']?.toString().split('T').first ?? '2026-08-08',
      memberTier: map['member_tier']?.toString() ?? 'Silver Member',
    );
  }
}
