// import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  pending,
  delivered,
  partial,
  urgent,
}

class Task {
  final String id;
  final String shopName;
  final String brand; // Brand selection (Prestine, Frozen, etc.)
  final String orderDetails; // Merged Stock Name + Quantity, supports multiline
  final String notes;
  final TaskStatus status;
  final DateTime createdAt;
  final String? partialDetails; // Details about partial delivery

  Task({
    required this.id,
    required this.shopName,
    required this.brand,
    required this.orderDetails,
    this.notes = '',
    required this.status,
    required this.createdAt,
    this.partialDetails,
  });

  /*
  factory Task.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      shopName: data['shopName'] ?? '',
      orderDetails: data['orderDetails'] ?? '',
      notes: data['notes'] ?? '',
      status: _mapStringToStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      partialDetails: data['partialDetails'],
    );
  }
  */

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'brand': brand,
      'orderDetails': orderDetails,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(), // Timestamp.fromDate(createdAt),
      'partialDetails': partialDetails,
    };
  }

  static TaskStatus _mapStringToStatus(String? status) {
    switch (status) {
      case 'delivered':
        return TaskStatus.delivered;
      case 'partial':
        return TaskStatus.partial;
      case 'urgent':
        return TaskStatus.urgent;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }
}
