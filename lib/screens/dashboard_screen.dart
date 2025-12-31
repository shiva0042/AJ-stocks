import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await _db.checkAndMarkUrgentTasks();
    });
  }

  void _markDelivered(Task task) async {
    await _db.updateTaskStatus(task.id, TaskStatus.delivered);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.shopName} marked as Delivered!')),
      );
    }
  }

  void _markPartial(Task task) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partial Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text('Enter details (e.g., delivered 5/10):'),
             const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '50kg delivered, 50kg pending',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _db.updateTaskStatus(
                  task.id,
                  TaskStatus.partial,
                  partialDetails: controller.text,
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _markPending(Task task) async {
    await _db.updateTaskStatus(task.id, TaskStatus.pending);
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.shopName} marked as Pending')),
      );
    }
  }

  void _editTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTaskScreen(task: task)),
    );
  }

  // Define brand colors
  final Color primaryBlue = const Color(0xFF4C4DDC); // approximate from image
  final Color bgGrey = const Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'AJ STOCKS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2),
            ),
            Text(
              'DELIVERY CONTROL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 2),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: primaryBlue,
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Task>>(
          stream: _db.tasksStream,
          initialData: _db.currentTasks,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final allTasks = snapshot.data!;
            
            // Calculate stats
            final activeCount = allTasks.where((t) => t.status != TaskStatus.delivered).length;
            final urgentCount = allTasks.where((t) => t.status == TaskStatus.urgent).length;
            final successCount = allTasks.where((t) => t.status == TaskStatus.delivered).length;
            final partialCount = allTasks.where((t) => t.status == TaskStatus.partial).length;

            return IndexedStack(
              index: _currentIndex,
              children: [
                // 0: HOME DASHBOARD
                _buildHomeView(allTasks, activeCount, urgentCount, successCount, partialCount),
                 // 1: PENDING (Active)
                _buildTaskList(allTasks.where((t) => t.status != TaskStatus.delivered).toList(), isDeliveredView: false),
                 // 2: Placeholder for FAB (handled by location)
                Container(), 
                // 3: DELIVERED
                _buildTaskList(allTasks.where((t) => t.status == TaskStatus.delivered).toList(), isDeliveredView: true),
                // 4: AI INSIGHTS
                const Center(child: Text("AI Insights Coming Soon")),
              ],
            );
          },
        ),
      
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskScreen()),
            );
          },
          backgroundColor: primaryBlue,
          elevation: 10,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) return; // middle button is FAB
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Pending'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''), // Spacer for FAB
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Delivered'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Insights'),
        ],
      ),
    );
  }

  Widget _buildHomeView(List<Task> tasks, int active, int urgent, int success, int partial) {
    // Recent tasks: take top 5 active, or just top 5 recent
    final recentTasks = tasks.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header / Stats Card
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: const BorderRadius.only(
                 bottomLeft: Radius.circular(24),
                 bottomRight: Radius.circular(24),
               ),
               boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
               ],
             ),
             child: Container(
               decoration: BoxDecoration(
                 color: primaryBlue,
                 borderRadius: BorderRadius.circular(24),
                 boxShadow: [
                   BoxShadow(color: primaryBlue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
                 ],
               ),
               padding: const EdgeInsets.all(20),
               child: Column(
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: const [
                       Text("GLOBAL STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                       Icon(Icons.bar_chart, color: Colors.white70),
                     ],
                   ),
                   const SizedBox(height: 20),
                   Row(
                     children: [
                       Expanded(child: _buildStatItem(active.toString(), "TOTAL ACTIVE")),
                       const SizedBox(width: 12),
                       Expanded(child: _buildStatItem(urgent.toString(), "URGENT ACTION")),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       Expanded(child: _buildStatItem(success.toString(), "SUCCESS")),
                       const SizedBox(width: 12),
                       Expanded(child: _buildStatItem(partial.toString(), "SPLIT DROPS")),
                     ],
                   )
                 ],
               ),
             ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Tasks Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "RECENT TASKS",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey[800],
                    letterSpacing: 1,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1), // Go to pending
                  child: Text("View All", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List or Empty State
          if (recentTasks.isEmpty) 
             _buildEmptyState()
          else
             ListView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               itemCount: recentTasks.length,
               itemBuilder: (context, index) {
                 final task = recentTasks[index];
                 // Determine callbacks based on status
                 final isDelivered = task.status == TaskStatus.delivered;
                 return TaskCard(
                    task: task,
                    onDelivered: isDelivered ? () {} : () => _markDelivered(task),
                    onPartial: isDelivered ? () {} : () => _markPartial(task),
                    onEdit: () => _editTask(task),
                    onUndo: isDelivered ? () => _markPending(task) : null,
                 );
               },
             ),
           
           const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "All tasks completed. Relax or add a new one!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, {required bool isDeliveredView}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDeliveredView ? Icons.check_circle_outline : Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isDeliveredView ? "No delivered tasks yet" : "No pending tasks",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 90),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onDelivered: isDeliveredView ? () {} : () => _markDelivered(task),
          onPartial: isDeliveredView ? () {} : () => _markPartial(task),
          onEdit: () => _editTask(task),
          onUndo: isDeliveredView ? () => _markPending(task) : null,
        );
      },
    );
  }
}
