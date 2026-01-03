import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TimeOfDay _notificationTime = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final time = await NotificationService().getSavedNotificationTime();
    setState(() {
      _notificationTime = time;
    });
  }

  Future<void> _pickTime() async {
    try {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _notificationTime,
      );
      
      if (picked == null || picked == _notificationTime) return;
      
      setState(() {
        _notificationTime = picked;
      });
      
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduling notification...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Reschedule with timeout
      await NotificationService()
          .scheduleDailyNotification(time: picked)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Scheduling timeout - please try again');
            },
          );
      
      // Calculate delay for user feedback
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
      final diff = scheduledDate.difference(now);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification scheduled for ${picked.format(context)}\n'
              '(in ${diff.inHours}h ${diff.inMinutes % 60}m). Close app now!',
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
        
        // Immediate visual confirmation
        await NotificationService().showInstantNotification(
           title: "✓ Scheduled Successfully",
           body: "Notification set for ${picked.format(context)}"
        );
      }
    } catch (e) {
      print("ERROR in _pickTime: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("NOTIFICATIONS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_active, color: Colors.teal),
                      ),
                      title: const Text("Daily Briefing Time"),
                      subtitle: Text("Receive updates at ${_notificationTime.format(context)}"),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _pickTime,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.notification_important, color: Colors.orange),
                      ),
                      title: const Text("Test Notification"),
                      subtitle: const Text("Send an immediate test alert"),
                      onTap: () async {
                        await NotificationService().showInstantNotification(
                          title: "Test Alert",
                          body: "This is a test notification from AJ Stocks!",
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Test notification sent!")),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.timer, color: Colors.purple),
                      ),
                      title: const Text("Test: Schedule 30 Sec"),
                      subtitle: const Text("Schedule notification for 30 seconds (KEEP APP OPEN)"),
                      onTap: () async {
                        try {
                          final result = await NotificationService().scheduleTestIn30Seconds();
                          if (mounted) {
                            final isError = result.startsWith("ERROR");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result),
                                duration: const Duration(seconds: 5),
                                backgroundColor: isError ? Colors.red : Colors.purple,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("CRASH: $e"),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text("APP INFO", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
                      title: const Text("Version"),
                      trailing: const Text("1.0.0", style: TextStyle(color: Colors.grey)),
                    ),
                     const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud_done, color: Colors.blue),
                      title: const Text("Database"),
                      trailing: const Text("Firebase / Mock", style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
