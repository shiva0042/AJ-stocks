import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import 'package:csv/csv.dart';
import '../utils/csv_exporter.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Task> tasks;

  const AnalyticsScreen({super.key, required this.tasks});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Week'; // Day, Week, Month, Year, All
  TaskStatus? _selectedStatus;
  String? _selectedBrand;
  DateTime _focusedDate = DateTime.now();

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _focusedDate) {
      setState(() {
        _focusedDate = picked;
        _selectedStatus = null;
        _selectedBrand = null;
      });
    }
  }

  Future<void> _exportToCsv(List<Task> tasks) async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data to export for this period.")),
      );
      return;
    }

    // Prepare CSV Data
    final List<List<dynamic>> rows = [
      ['DATE', 'SHOP NAME', 'BRAND(S)', 'ORDER DETAILS', 'STATUS', 'NOTES']
    ];

    for (var task in tasks) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt),
        task.shopName,
        task.brand,
        task.orderDetails.replaceAll('\n', ' | '),
        task.status.name.toUpperCase(),
        task.notes,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final filename = "AJ_Stocks_${_selectedPeriod}_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv";
    
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Exporting CSV...")),
      );
    }
    
    final filePath = await CsvExporter.export(csvData, filename);
    
    if (mounted) {
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("CSV exported! Choose where to save it from the Share menu."),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Export cancelled or failed."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4C4DDC);
    const secondaryBlue = Color(0xFF6C63FF);
    
    // 1. Filter tasks based on selected period and focused date
    List<Task> periodTasks = [];
    
    switch (_selectedPeriod) {
      case 'Day':
        periodTasks = widget.tasks.where((t) => 
          t.createdAt.year == _focusedDate.year && 
          t.createdAt.month == _focusedDate.month && 
          t.createdAt.day == _focusedDate.day
        ).toList();
        break;
      case 'Week':
        final startOfWeek = _focusedDate.subtract(const Duration(days: 7));
        periodTasks = widget.tasks.where((t) => 
          t.createdAt.isAfter(startOfWeek) && t.createdAt.isBefore(_focusedDate.add(const Duration(days: 1)))
        ).toList();
        break;
      case 'Month':
        periodTasks = widget.tasks.where((t) => 
          t.createdAt.year == _focusedDate.year && 
          t.createdAt.month == _focusedDate.month
        ).toList();
        break;
      case 'Year':
        periodTasks = widget.tasks.where((t) => t.createdAt.year == _focusedDate.year).toList();
        break;
      case 'All':
        periodTasks = widget.tasks;
        break;
    }

    // 2. Brand Analysis Logic
    final brandMap = <String, int>{};
    for (var task in periodTasks) {
      final brands = task.brand.split(', ');
      for (var b in brands) {
        if (b.trim().isNotEmpty) {
          brandMap[b] = (brandMap[b] ?? 0) + 1;
        }
      }
    }
    final sortedBrands = brandMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxBrandCount = sortedBrands.isEmpty ? 1 : sortedBrands.first.value;

    // 3. Final Filter for Display
    List<Task> displayTasks = periodTasks;
    if (_selectedStatus != null) {
      displayTasks = displayTasks.where((t) => t.status == _selectedStatus).toList();
    }
    if (_selectedBrand != null) {
      displayTasks = displayTasks.where((t) => t.brand.split(', ').contains(_selectedBrand)).toList();
    }
    displayTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Stats
    int total = periodTasks.length;
    int delivered = periodTasks.where((t) => t.status == TaskStatus.delivered).length;
    int pending = periodTasks.where((t) => t.status == TaskStatus.pending).length;
    int urgent = periodTasks.where((t) => t.status == TaskStatus.urgent).length;
    int partial = periodTasks.where((t) => t.status == TaskStatus.partial).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _exportToCsv(periodTasks),
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download Report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Header Area with Period Selector
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    children: [
                       Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['Day', 'Week', 'Month', 'Year', 'All'].map((period) {
                            final isSelected = _selectedPeriod == period;
                            return GestureDetector(
                              onTap: () => setState(() { _selectedPeriod = period; _selectedStatus = null; _selectedBrand = null; }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(period, style: TextStyle(color: isSelected ? primaryBlue : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Dynamic Focus Selector
                      if (_selectedPeriod != 'All')
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _getSelectedRangeText(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        )
                      else
                        const Text(
                          "LIFETIME STATS",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat("Total Orders", "$total", Colors.white),
                          _buildHeaderStat("Completed", "$delivered", Colors.greenAccent),
                        ],
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Breakdown
                      _buildSectionTitle("DELIVERY DYNAMICS"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard('Urgent', urgent, Colors.redAccent, Icons.priority_high, TaskStatus.urgent)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard('Partial', partial, Colors.orangeAccent, Icons.hourglass_bottom, TaskStatus.partial)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard('Pending', pending, Colors.blueGrey, Icons.schedule, TaskStatus.pending)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Brand Distribution Visualization
                      _buildSectionTitle("BRAND DOMINANCE"),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(
                          children: [
                            if (sortedBrands.isEmpty) 
                              const Center(child: Text("No brand data available", style: TextStyle(color: Colors.grey)))
                            else 
                              ...sortedBrands.map((entry) {
                                final isSelected = _selectedBrand == entry.key;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedBrand = isSelected ? null : entry.key),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(entry.key, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: isSelected ? primaryBlue : Colors.blueGrey[800])),
                                            Text("${entry.value} Orders", style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue.withOpacity(0.7), fontSize: 12)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Stack(
                                          children: [
                                            Container(
                                              height: 10,
                                              width: double.infinity,
                                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 600),
                                              curve: Curves.easeOut,
                                              height: 10,
                                              width: (MediaQuery.of(context).size.width - 80) * (entry.value / maxBrandCount),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: isSelected ? [primaryBlue, secondaryBlue] : [Colors.blueGrey[300]!, Colors.blueGrey[400]!]),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Activity List
                      _buildSectionTitle(
                        _selectedBrand != null 
                          ? "$_selectedBrand RECENT ACTIVITY"
                          : _selectedStatus != null 
                            ? "${_selectedStatus!.name.toUpperCase()} RECENT ACTIVITY"
                            : "RECENT ACTIVITY"
                      ),
                      const SizedBox(height: 12),
                      if (displayTasks.isEmpty)
                        Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("No active orders match this filter", style: TextStyle(color: Colors.grey[400]))))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayTasks.length,
                          itemBuilder: (ctx, index) {
                            return TaskCard(
                              task: displayTasks[index],
                              onDelivered: () {}, 
                              onPartial: () {},
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMetricCard(String label, int count, Color color, IconData icon, TaskStatus status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = isSelected ? null : status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text('$count', style: TextStyle(color: isSelected ? color : Colors.blueGrey[800], fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _getSelectedRangeText() {
    switch (_selectedPeriod) {
      case 'Day':
        return DateFormat('EEE, MMM dd, yyyy').format(_focusedDate);
      case 'Week':
        final start = _focusedDate.subtract(const Duration(days: 7));
        return "${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(_focusedDate)}";
      case 'Month':
        return DateFormat('MMMM yyyy').format(_focusedDate);
      case 'Year':
        return DateFormat('yyyy').format(_focusedDate);
      default:
        return 'All Time';
    }
  }
}
