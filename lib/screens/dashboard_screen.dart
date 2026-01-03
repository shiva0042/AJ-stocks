import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'analytics_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// ... imports remain the same

class DashboardScreen extends StatefulWidget {
  final String? initError;
  const DashboardScreen({super.key, this.initError});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  int _currentIndex = 0;
  TaskStatus? _homeFilterStatus;
  String _selectedBrandFilter = 'All';

  // State helper methods...

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
       await _db.checkAndMarkUrgentTasks();
       _checkPermissions();
       
       if (widget.initError != null) {
         showDialog(
           context: context,
           builder: (ctx) => AlertDialog(
             title: const Text('Connection Failed'),
             content: Text('Could not connect to online database.\n\nError: ${widget.initError}\n\nApp is running in Offline Mock Mode.'),
             actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
           ),
         );
       }
    });
  }

  Future<void> _checkPermissions() async {
    try {
      // Step 1: Request Notification Permission
      var notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        notifStatus = await Permission.notification.request();
        if (!notifStatus.isGranted) {
          if (mounted) {
            _showPermissionDialog(
              'Notifications Required',
              'Please enable notifications to receive daily reminders.'
            );
          }
          return;
        }
      }
      
      // Step 2: Request Exact Alarm Permission (Android 12+)
      var alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus.isDenied) {
        alarmStatus = await Permission.scheduleExactAlarm.request();
        if (alarmStatus.isDenied) {
          if (mounted) {
            _showPermissionDialog(
              'Alarms Permission Required',
              'Please enable "Alarms & reminders" permission for scheduled notifications.'
            );
          }
          return;
        }
      }
      
      // Step 3: Request Battery Optimization Exemption (CRITICAL for background alarms)
      var batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Battery Optimization'),
              content: const Text(
                'To receive notifications when the app is closed, please disable battery optimization for AJ Stocks.\n\n'
                'This allows scheduled notifications to work reliably.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Permission.ignoreBatteryOptimizations.request();
                  },
                  child: const Text('Allow'),
                ),
              ],
            ),
          );
        }
      }
      
      print("All permissions granted successfully");
    } catch (e) {
      print("Error checking permissions: $e");
    }
  }

  void _showPermissionDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(ctx);
               openAppSettings();
            }, 
            child: const Text('Open Settings')
          ),
        ],
      ),
    );
  }

  Future<void> _refreshNotification() async {
    // Re-schedule with updated content based on new data
    final time = await NotificationService().getSavedNotificationTime();
    await NotificationService().scheduleDailyNotification(time: time);
  }

  void _markDelivered(Task task) async {
    await _db.updateTaskStatus(task.id, TaskStatus.delivered);
    _refreshNotification();
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
                _refreshNotification();
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
    _refreshNotification();
     if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${task.shopName} marked as Pending')),
      );
    }
  }

  void _updateStatus(Task task, TaskStatus newStatus) async {
    if (newStatus == TaskStatus.partial) {
      _markPartial(task);
    } else {
      await _db.updateTaskStatus(task.id, newStatus);
      _refreshNotification();
    }
  }

  void _editTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTaskScreen(task: task)),
    );
    _refreshNotification();
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete the task for "${task.shopName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.deleteTask(task.id);
              _refreshNotification();
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${task.shopName} deleted!')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _homeFilterStatus = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBody: true, // For transparency behind FAB/BottomNav if needed
        appBar: AppBar(
          leading: _currentIndex != 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => setState(() {
                  _currentIndex = 0;
                  _homeFilterStatus = null;
                }),
              )
            : null,
          title: GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 0;
                _homeFilterStatus = null;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AJ STOCKS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900, 
                    color: Colors.white,
                    letterSpacing: 1.2
                  ),
                ),
                Text(
                  'DELIVERY CONTROL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
          backgroundColor: primaryColor,
          elevation: 0,
          actions: [
            // Notification Bell with Badge Counter
            StreamBuilder<List<Task>>(
              stream: _db.tasksStream,
              builder: (context, snapshot) {
                final pendingCount = snapshot.hasData
                    ? snapshot.data!.where((t) => t.status != TaskStatus.delivered).length
                    : 0;
                
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        }, 
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            pendingCount > 99 ? '99+' : '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
             // Status Indicator (Red/Green)
             Container(
               width: 12,
               height: 12,
               margin: const EdgeInsets.fromLTRB(4, 0, 8, 0),
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: widget.initError == null ? Colors.greenAccent : Colors.redAccent,
                 border: Border.all(color: Colors.white, width: 2),
               ),
             ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: IconButton(
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                 },
                 icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<Task>>(
            stream: _db.tasksStream,
            initialData: _db.currentTasks,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
  
              final List<Task> fetchedTasks = snapshot.data!;
              
              // Sort by Date Descending
              fetchedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              // Get All Unique Brands for the filter list
              final allAvailableBrands = fetchedTasks.map((t) => t.brand).toSet().toList();
              allAvailableBrands.sort();
              final filterBrands = ['All', ...allAvailableBrands];

              // Apply Brand Filter
              final allTasks = _selectedBrandFilter == 'All' 
                  ? fetchedTasks 
                  : fetchedTasks.where((t) => t.brand.split(', ').contains(_selectedBrandFilter)).toList();
              
              // Calculate stats based on filtered tasks
              final activeCount = allTasks.where((t) => t.status != TaskStatus.delivered).length;
              final urgentCount = allTasks.where((t) => t.status == TaskStatus.urgent).length;
              final successCount = allTasks.where((t) => t.status == TaskStatus.delivered).length;
              final partialCount = allTasks.where((t) => t.status == TaskStatus.partial).length;
  
              return IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeView(allTasks, activeCount, urgentCount, successCount, partialCount, theme, filterBrands),
                  _buildTaskList(
                    allTasks.where((t) {
                      if (t.status == TaskStatus.delivered) return false;
                      if (_homeFilterStatus != null) return t.status == _homeFilterStatus;
                      return true;
                    }).toList(), 
                    isDeliveredView: false
                  ),
                  const SizedBox.shrink(), // FAB Spacer
                  _buildTaskList(allTasks.where((t) => t.status == TaskStatus.delivered).toList(), isDeliveredView: true),
                  _buildSimpleView("AI Insights", theme),
                ],
              );
            },
          ),
        
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskScreen()),
            );
          },
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }



  Widget _buildHomeView(List<Task> allTasks, int active, int urgent, int success, int partial, ThemeData theme, List<String> availableBrands) {
    final recentTasks = allTasks.take(5).toList();

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [ 
              // Header Background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Overview",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Brand Filter Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: availableBrands.contains(_selectedBrandFilter) ? _selectedBrandFilter : 'All',
                                    dropdownColor: theme.colorScheme.primary,
                                    icon: const Icon(Icons.filter_list, color: Colors.white70, size: 16),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    items: availableBrands.map((brand) {
                                      return DropdownMenuItem(
                                        value: brand,
                                        child: Text(brand),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedBrandFilter = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => AnalyticsScreen(tasks: allTasks))
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: Row(
                                children: const [
                                  Text("Analytics", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildStatItem(active.toString(), "Active Orders", Icons.local_shipping, () => setState(() { _currentIndex = 1; _homeFilterStatus = null; }), 
                            colors: [Colors.blue.shade400, Colors.blue.shade600])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatItem(urgent.toString(), "Urgent Actions", Icons.warning_rounded, () => setState(() { _currentIndex = 1; _homeFilterStatus = TaskStatus.urgent; }), 
                            colors: [const Color(0xFFFF8A65), const Color(0xFFFF5722)], isUrgent: true)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatItem(success.toString(), "Completed", Icons.check_circle, () => setState(() { _currentIndex = 3; _homeFilterStatus = null; }), 
                            colors: [Colors.green.shade400, Colors.green.shade600])),
                          const SizedBox(width: 12),
                          Expanded(child: _buildStatItem(partial.toString(), "Split Deliveries", Icons.hourglass_bottom_rounded, () => setState(() { _currentIndex = 1; _homeFilterStatus = TaskStatus.partial; }), 
                            colors: [Colors.orange.shade300, Colors.deepOrange.shade400])),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Activity",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 1),
                      child: Text("View All", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
    
              const SizedBox(height: 8),
    
              recentTasks.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                   padding: const EdgeInsets.symmetric(horizontal: 4),
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: recentTasks.length,
                   itemBuilder: (context, index) {
                     final task = recentTasks[index];
                     final isDelivered = task.status == TaskStatus.delivered;
                     return TaskCard(
                        task: task,
                        onDelivered: isDelivered ? () {} : () => _markDelivered(task),
                        onPartial: isDelivered ? () {} : () => _markPartial(task),
                        onEdit: () => _editTask(task),
                        onUndo: isDelivered ? () => _markPending(task) : null,
                        onDelete: () => _deleteTask(task),
                        onStatusChanged: (newStatus) => _updateStatus(task, newStatus!),
                     );
                   },
                 ),
               
               const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon, VoidCallback? onTap, {List<Color>? colors, bool isUrgent = false}) {
    final gradientColors = colors ?? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, // Increased height significantly to prevent overflow
        padding: const EdgeInsets.all(16), // Reduced padding slightly to give more room
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
             BoxShadow(color: gradientColors.last.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 28), 
                if(isUrgent) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.0),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      // ... same styling with updated colors if needed ...
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text("No tasks yet", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSimpleView(String title, ThemeData theme) {
    return Center(
      child: Text(title, style: theme.textTheme.headlineMedium),
    );
  }

  Widget _buildTaskList(List<Task> tasks, {required bool isDeliveredView}) {
    Widget content;
    if (tasks.isEmpty) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDeliveredView ? Icons.check_circle_outline : Icons.local_shipping_outlined, size: 64, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              isDeliveredView ? "No delivered tasks" : "No pending tasks",
              style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onDelivered: isDeliveredView ? () {} : () => _markDelivered(task),
            onPartial: isDeliveredView ? () {} : () => _markPartial(task),
            onEdit: () => _editTask(task),
            onUndo: isDeliveredView ? () => _markPending(task) : null,
            onDelete: () => _deleteTask(task),
            onStatusChanged: (newStatus) => _updateStatus(task, newStatus!),
          );
        },
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: content,
      ),
    );
  }
}
