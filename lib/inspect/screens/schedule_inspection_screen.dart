import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class ScheduleInspectionScreen extends StatefulWidget {
  const ScheduleInspectionScreen({super.key});

  @override
  State<ScheduleInspectionScreen> createState() => _ScheduleInspectionScreenState();
}

class _ScheduleInspectionScreenState extends State<ScheduleInspectionScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    ComplaintModel? c;
    if (args is ComplaintModel) {
      c = args;
    } else if (MockSeedData.complaints.isNotEmpty) {
      c = MockSeedData.complaints.first;
    }

    if (c == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Schedule Visit'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No complaint available to schedule an inspection.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Schedule Visit'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Set Visit Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Linked Complaint ID: ${c.id}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blueGrey),
                      title: const Text('Visit Date'),
                      subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: const Text('Change Date'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.blueGrey),
                      title: const Text('Visit Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) setState(() => _selectedTime = picked);
                        },
                        child: const Text('Change Time'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            CustomButton(
              label: 'Confirm Visit',
              icon: Icons.event_available,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visit scheduled successfully! Premise notified.')),
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
