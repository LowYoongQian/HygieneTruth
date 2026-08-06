import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../widgets/role_badge.dart';

class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({super.key});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late UserModel _selectedUser;
  late UserRole _selectedRole;
  late AccountStatus _selectedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel) {
      _selectedUser = args;
    } else {
      _selectedUser = MockSeedData.users.first;
    }
    _selectedRole = _selectedUser.role;
    _selectedStatus = _selectedUser.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'User Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(_selectedUser.avatarUrl),
                  ),
                  const SizedBox(height: 8),
                  Text(_selectedUser.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(_selectedUser.email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  RoleBadge(role: _selectedRole),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Admin Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assign User Role', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserRole>(
                      isExpanded: true,
                      initialValue: _selectedRole,
                      items: UserRole.values.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Account Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AccountStatus>(
                      isExpanded: true,
                      initialValue: _selectedStatus,
                      items: AccountStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Save Changes',
              icon: Icons.save,
              backgroundColor: Colors.green.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_selectedUser.name} profile updated.')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Suspend User',
              icon: Icons.block,
              backgroundColor: Colors.red.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_selectedUser.name} suspended.')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
