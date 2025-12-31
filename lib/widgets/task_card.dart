import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onDelivered;
  final VoidCallback onPartial;
  final VoidCallback? onUndo;
  final VoidCallback? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onDelivered,
    required this.onPartial,
    this.onUndo,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.urgent:
        cardColor = Colors.red.shade50;
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        break;
      case TaskStatus.partial:
        cardColor = Colors.orange.shade50;
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_bottom_rounded;
        break;
      case TaskStatus.delivered:
        cardColor = Colors.green.shade50;
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case TaskStatus.pending:
      default:
        cardColor = Colors.white;
        statusColor = Colors.blueGrey;
        statusIcon = Icons.inventory_2_outlined;
        break;
    }

    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.shopName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.grey,
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                Icon(statusIcon, color: statusColor, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.orderDetails,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            if (task.status == TaskStatus.partial &&
                task.partialDetails != null) ...[
              const SizedBox(height: 8),
              Text(
                'Partial Delivery: ${task.partialDetails}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
            if (task.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${task.notes}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(task.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (task.status != TaskStatus.delivered)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onPartial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade900,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Partial'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onDelivered,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade900,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Delivered'),
                      ),
                    ],
                  ),
                if (task.status == TaskStatus.delivered && onUndo != null)
                   ElevatedButton.icon(
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Undo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
                   ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
