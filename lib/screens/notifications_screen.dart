import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Task> _pendingTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingTasks();
  }

  Future<void> _loadPendingTasks() async {
    setState(() => _loading = true);
    try {
      final allTasks = await DatabaseService().getAllTasks();
      final pending = allTasks.where((t) => t.status != TaskStatus.delivered).toList();
      
      // Sort: Urgent first, then by date
      pending.sort((a, b) {
        if (a.status == TaskStatus.urgent && b.status != TaskStatus.urgent) return -1;
        if (a.status != TaskStatus.urgent && b.status == TaskStatus.urgent) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      setState(() {
        _pendingTasks = pending;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print("Error loading pending tasks: $e");
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.urgent:
        return Colors.red;
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.partial:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.urgent:
        return 'URGENT';
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.partial:
        return 'PARTIAL';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Orders'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'All caught up!',
                        style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pending orders',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingTasks.length,
                    itemBuilder: (context, index) {
                      final task = _pendingTasks[index];
                      final statusColor = _getStatusColor(task.status);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              task.status == TaskStatus.urgent
                                  ? Icons.priority_high
                                  : task.status == TaskStatus.partial
                                      ? Icons.splitscreen
                                      : Icons.pending_actions,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            task.shopName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                task.orderDetails.length > 50
                                    ? '${task.orderDetails.substring(0, 50)}...'
                                    : task.orderDetails,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getStatusText(task.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Could navigate to task details if needed
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
