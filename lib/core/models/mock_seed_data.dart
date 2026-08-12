import 'user_model.dart';
import 'restaurant_model.dart';
import 'complaint_model.dart';
import 'inspection_model.dart';

class MockSeedData {
  static const List<UserModel> users = [
    UserModel(
      id: 'usr_001',
      name: 'User Account',
      email: 'user@example.com',
      phone: '+6012-3456789',
      role: UserRole.user,
      status: AccountStatus.active,
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    UserModel(
      id: 'adm_001',
      name: 'System Admin',
      email: 'admin@hygiene.gov.my',
      phone: '+6019-8765432',
      role: UserRole.admin,
      status: AccountStatus.active,
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
    ),
    UserModel(
      id: 'gov_001',
      name: 'Health Officer (PIC)',
      email: 'officer.pic@hygiene.gov.my',
      phone: '+6017-1122334',
      role: UserRole.government,
      status: AccountStatus.active,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    UserModel(
      id: 'own_001',
      name: 'Businessman Account',
      email: 'owner@bistro.com',
      phone: '+6013-9988776',
      role: UserRole.owner,
      status: AccountStatus.active,
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
    ),
  ];

  static List<RestaurantModel> restaurants = [];
  static List<ComplaintModel> complaints = [];
  static List<InspectionModel> inspections = [];
}
