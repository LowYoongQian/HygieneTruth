import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class IssueEnforcementScreen extends StatefulWidget {
  const IssueEnforcementScreen({super.key});

  @override
  State<IssueEnforcementScreen> createState() => _IssueEnforcementScreenState();
}

class _IssueEnforcementScreenState extends State<IssueEnforcementScreen> {
  EnforcementType _selectedAction = EnforcementType.closure;
  final _fineCtrl = TextEditingController(text: '2500.00');
  final _justificationCtrl = TextEditingController();

  final EnforcementType _recommendedAction = EnforcementType.closure;

  @override
  Widget build(BuildContext context) {
    final isActionDifferent = _selectedAction != _recommendedAction;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Issue Action'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.recommend, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recommended Action:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(_recommendedAction.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Action Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<EnforcementType>(
              isExpanded: true,
              initialValue: _selectedAction,
              items: EnforcementType.values.map((e) {
                return DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedAction = val);
              },
            ),
            const SizedBox(height: 16),
            if (_selectedAction == EnforcementType.fine || _selectedAction == EnforcementType.closure)
              TextField(
                controller: _fineCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fine Amount (RM)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            const SizedBox(height: 16),
            if (isActionDifferent) ...[
              TextField(
                controller: _justificationCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Justification *',
                  hintText: 'Explain reason...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
            CustomButton(
              label: 'Issue Action',
              icon: Icons.gavel,
              backgroundColor: Colors.red.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enforcement action issued successfully!')),
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
