import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';

class NotificationScreen extends StatelessWidget {
  final List<Task> tasks;

  const NotificationScreen({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Filter for Urgent and Pending tasks
    final criticalTasks = tasks.where((t) => 
      t.status == TaskStatus.urgent || t.status == TaskStatus.pending
    ).toList();
    
    // Sort Urgent first, then Pending
    criticalTasks.sort((a, b) {
      if (a.status == TaskStatus.urgent && b.status != TaskStatus.urgent) return -1;
      if (b.status == TaskStatus.urgent && a.status != TaskStatus.urgent) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Priority Updates', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: criticalTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                   const SizedBox(height: 16),
                   const Text("All Caught Up!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                   const Text("No pending or urgent tasks.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: criticalTasks.length,
              itemBuilder: (ctx, index) {
                return TaskCard(
                  task: criticalTasks[index],
                  onDelivered: () {}, 
                  onPartial: () {},
                  // Read-only or simplified view
                );
              },
            ),
    );
  }
}
