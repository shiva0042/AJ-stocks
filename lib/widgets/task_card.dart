import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onDelivered;
  final VoidCallback onPartial;
  final VoidCallback? onUndo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<TaskStatus?>? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onDelivered,
    required this.onPartial,
    this.onUndo,
    this.onEdit,
    this.onDelete,
    this.onStatusChanged,
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
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: onDelete,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TaskStatus>(
                  value: task.status,
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                  items: TaskStatus.values.map((status) {
                     Color c = Colors.grey;
                     if(status == TaskStatus.urgent) c = Colors.red;
                     if(status == TaskStatus.delivered) c = Colors.green;
                     if(status == TaskStatus.partial) c = Colors.orange;
                     if(status == TaskStatus.pending) c = Colors.blueGrey;
                     
                     return DropdownMenuItem(
                       value: status, 
                       child: Text(
                         status.name.toUpperCase(), 
                         style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)
                       )
                     );
                  }).toList(),
                  onChanged: onStatusChanged,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(task.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
