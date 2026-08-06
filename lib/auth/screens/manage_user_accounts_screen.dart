import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/role_badge.dart';

class ManageUserAccountsScreen extends StatelessWidget {
  const ManageUserAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = MockSeedData.users;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Users'),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RoleBadge(role: user.role),
                      const SizedBox(width: 8),
                      StatusBadge.fromStatus(user.status.name),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.edit_note, color: Colors.purple),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.accountDetail,
                  arguments: user,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
