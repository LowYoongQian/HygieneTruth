import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class ConductInspectionScreen extends StatefulWidget {
  const ConductInspectionScreen({super.key});

  @override
  State<ConductInspectionScreen> createState() => _ConductInspectionScreenState();
}

class _ConductInspectionScreenState extends State<ConductInspectionScreen> {
  InspectionOutcome _outcome = InspectionOutcome.nonCompliant;
  final _findingsCtrl = TextEditingController(
    text: 'Found unhygienic food storage and active pest presence near cooking area.',
  );
  bool _photoAttached = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Record Visit'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Outcome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SegmentedButton<InspectionOutcome>(
              segments: const [
                ButtonSegment<InspectionOutcome>(
                  value: InspectionOutcome.compliant,
                  label: Text('Compliant'),
                  icon: Icon(Icons.check_circle, color: Colors.green),
                ),
                ButtonSegment<InspectionOutcome>(
                  value: InspectionOutcome.nonCompliant,
                  label: Text('Non-compliant'),
                  icon: Icon(Icons.warning, color: Colors.red),
                ),
              ],
              selected: {_outcome},
              onSelectionChanged: (Set<InspectionOutcome> selection) {
                setState(() {
                  _outcome = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _findingsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Findings *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(_photoAttached ? Icons.photo_library : Icons.add_a_photo, color: Colors.teal),
                title: Text(_photoAttached ? 'Evidence Photo Attached' : 'Attach Photo Evidence'),
                subtitle: const Text('Mandatory for non-compliant cases'),
                trailing: Switch(
                  value: _photoAttached,
                  onChanged: (val) => setState(() => _photoAttached = val),
                ),
              ),
            ),
            const SizedBox(height: 30),
            CustomButton(
              label: 'Submit Report',
              icon: Icons.send,
              onPressed: () {
                if (_findingsCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter findings.')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted to Admin!')),
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
