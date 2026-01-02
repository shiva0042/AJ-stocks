import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

// ... imports remain the same

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
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.urgent:
        statusColor = const Color(0xFFFF5722); // Deep Orange
        statusIcon = Icons.warning_rounded;
        break;
      case TaskStatus.partial:
        statusColor = const Color(0xFFFFB74D); // Orange Light
        statusIcon = Icons.hourglass_bottom_rounded;
        break;
      case TaskStatus.delivered:
        statusColor = const Color(0xFF00C853); // Green Accent
        statusIcon = Icons.check_circle_rounded;
        break;
      case TaskStatus.pending:
      default:
        statusColor = const Color(0xFF90A4AE); // Blue Grey
        statusIcon = Icons.inventory_2_outlined;
        break;
    }

    final dateFormat = DateFormat('MMM dd • hh:mm a');
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored Status Bar Indicator
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Shop Name & Status Icon
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.shopName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Multi-Brand Badges
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: task.brand.split(', ').map((b) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      b.toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 18),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Order Details
                      Text(
                        task.orderDetails,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.3
                        ),
                      ),
                      
                      const SizedBox(height: 8),

                      // Metadata Row (Partial Info or Date)
                      if (task.status == TaskStatus.partial && task.partialDetails != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade100),
                          ),
                          child: Text(
                            'Partial: ${task.partialDetails}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),

                      if (task.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.sticky_note_2_outlined, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.notes,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Divider(height: 24, thickness: 0.5),

                      // Status Buttons Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskStatus.values.map((status) {
                          final isSelected = task.status == status;
                          Color baseColor;
                          switch (status) {
                            case TaskStatus.urgent: baseColor = const Color(0xFFFF5722); break;
                            case TaskStatus.partial: baseColor = const Color(0xFFFFB74D); break;
                            case TaskStatus.delivered: baseColor = const Color(0xFF00C853); break;
                            case TaskStatus.pending: default: baseColor = const Color(0xFF90A4AE); break;
                          }

                          return InkWell(
                            onTap: () => onStatusChanged?.call(status),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? baseColor : baseColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? baseColor : baseColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : baseColor.withOpacity(0.8),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Footer: Date & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(task.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              if (onEdit != null)
                                InkWell(
                                  onTap: onEdit,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[400]),
                                  ),
                                ),
                              if (onDelete != null)
                                InkWell(
                                  onTap: onDelete,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red[300]),
                                  ),
                                ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
