import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/task_model.dart';
// import 'package:firebase_core/firebase_core.dart';

class DatabaseService {
  // Mock Data Source
  static final List<Task> _mockTasks = [];
  static final StreamController<List<Task>> _controller = StreamController<List<Task>>.broadcast();

  // Flag to switch between Mock and Firebase
  static bool _useMock = false; 

  static void enableMock() {
    print('DATABASE: Switching to MOCK mode.');
    _useMock = true;
  }

  // Realtime Database Reference
  DatabaseReference get _tasksRef => 
      FirebaseDatabase.instance.ref('tasks');

  // Helper to emit current mock state
  static void _emitMock() {
    final list = List<Task>.from(_mockTasks);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(list);
  }

  // --- STREAM ---
  Stream<List<Task>> get tasksStream {
    if (_useMock) {
      // Mock Stream logic
      final current = List<Task>.from(_mockTasks);
      current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.multi((controller) {
        controller.add(current);
        final sub = _controller.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });
    } else {
      // Realtime Database Stream
      return _tasksRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return <Task>[];

        final Map<dynamic, dynamic> map = data as Map<dynamic, dynamic>;
        final tasks = map.entries.map((e) {
          final val = e.value as Map;
          return Task(
            id: e.key.toString(),
            shopName: val['shopName'] ?? '',
            brand: val['brand'] ?? 'Others',
            orderDetails: val['orderDetails'] ?? '',
            notes: val['notes'] ?? '',
            status: TaskStatus.values.firstWhere(
              (s) => s.toString() == val['status'],
              orElse: () => TaskStatus.pending,
            ),
            createdAt: val['createdAt'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(val['createdAt'] as int) 
                : DateTime.now(),
            partialDetails: val['partialDetails'],
          );
        }).toList();
        
        // Sort by date desc
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return tasks;
      });
    }
  }

  // --- SYNC GETTER (Mock Only) ---
  List<Task> get currentTasks {
    if (_useMock) {
      final list = List<Task>.from(_mockTasks);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    return []; 
  }

  // --- ADD TASK ---
  Future<void> addTask(Task task) async {
    if (_useMock) {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shopName: task.shopName,
        brand: task.brand,
        orderDetails: task.orderDetails,
        notes: task.notes,
        status: task.status,
        createdAt: task.createdAt,
        partialDetails: task.partialDetails,
      );
      _mockTasks.add(newTask);
      _emitMock();
    } else {
      try {
        await _tasksRef.push().set({
          'shopName': task.shopName,
          'brand': task.brand,
          'orderDetails': task.orderDetails,
          'notes': task.notes,
          'status': task.status.toString(),
          'createdAt': task.createdAt.millisecondsSinceEpoch,
          'partialDetails': task.partialDetails,
        }).timeout(const Duration(seconds: 5));
      } catch (e) {
        print('DB ERROR: Add task failed: $e');
        // Fallback or rethrow
        rethrow;
      }
    }
  }

  // --- UPDATE DETAILS ---
  Future<void> updateTaskDetails(Task task) async {
    if (_useMock) {
      final index = _mockTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _mockTasks[index] = task;
        _emitMock();
      }
    } else {
      try {
        await _tasksRef.child(task.id).update({
          'shopName': task.shopName,
          'brand': task.brand,
          'orderDetails': task.orderDetails,
          'notes': task.notes,
        }).timeout(const Duration(seconds: 5));
      } catch (e) {
         print('DB ERROR: Update details failed: $e');
         rethrow;
      }
    }
  }

  // --- UPDATE STATUS ---
  Future<void> updateTaskStatus(String id, TaskStatus status, {String? partialDetails}) async {
    if (_useMock) {
      final index = _mockTasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final old = _mockTasks[index];
        _mockTasks[index] = Task(
          id: old.id,
          shopName: old.shopName,
          brand: old.brand,
          orderDetails: old.orderDetails,
          notes: old.notes,
          status: status,
          createdAt: old.createdAt,
          partialDetails: partialDetails ?? old.partialDetails,
        );
        _emitMock();
      }
    } else {
      try {
        final data = {
          'status': status.toString(),
        };
        if (partialDetails != null) {
          data['partialDetails'] = partialDetails;
        }
        await _tasksRef.child(id).update(data).timeout(const Duration(seconds: 5));
      } catch (e) {
          print('DB ERROR: Update status failed: $e');
          rethrow;
      }
    }
  }

  // --- DELETE TASK ---
  Future<void> deleteTask(String id) async {
    if (_useMock) {
      _mockTasks.removeWhere((t) => t.id == id);
      _emitMock();
    } else {
      try {
        await _tasksRef.child(id).remove().timeout(const Duration(seconds: 5));
      } catch (e) {
        print('DB ERROR: Delete task failed: $e');
        rethrow;
      }
    }
  }

  // --- CHECK URGENT (Mock Only for simplicity) ---
  Future<void> checkAndMarkUrgentTasks() async {
    if (_useMock) {
       final now = DateTime.now();
       final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
       bool changed = false;
        for (int i = 0; i < _mockTasks.length; i++) {
          final t = _mockTasks[i];
          if (t.status != TaskStatus.delivered && t.status != TaskStatus.urgent) {
            if (t.createdAt.isBefore(twentyFourHoursAgo)) {
               _mockTasks[i] = Task(
                id: t.id,
                shopName: t.shopName,
                brand: t.brand,
                orderDetails: t.orderDetails,
                notes: t.notes,
                status: TaskStatus.urgent,
                createdAt: t.createdAt,
                partialDetails: t.partialDetails,
              );
              changed = true;
            }
          }
        }
        if (changed) _emitMock();
    }
  }
}
