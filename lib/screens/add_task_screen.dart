import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _shopController;
  late TextEditingController _notesController;
  
  // Dynamic Inventory List
  // Each item is {name: Controller, qty: Controller}
  final List<Map<String, TextEditingController>> _inventoryItems = [];

  bool _isLoading = false;

  // Colors
  final Color primaryBlue = const Color(0xFF4C4DDC);
  final Color bgGrey = const Color(0xFFF4F6F8);
  final Color labelColor = const Color(0xFF8A94A6);

  // Date Selection
  bool _isToday = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _shopController = TextEditingController(text: widget.task?.shopName ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    
    _initInventory();
    _initDate();
  }

  void _initDate() {
    if (widget.task != null) {
      _selectedDate = widget.task!.createdAt;
      final now = DateTime.now();
      // Check if task date is same day as today
      _isToday = _selectedDate.year == now.year && 
                 _selectedDate.month == now.month && 
                 _selectedDate.day == now.day;
    }
  }

  void _initInventory() {
    if (widget.task != null && widget.task!.orderDetails.isNotEmpty) {
      // Parse existing string: "ItemName Quantity" or "ItemName - Quantity" per line
      final lines = widget.task!.orderDetails.split('\n');
      for (var line in lines) {
         if (line.trim().isEmpty) continue;
         // Naive split attempt
         _addNewItemRow(initialName: line);
      }
    } else {
      // Start with one empty row
      _addNewItemRow();
    }
  }

  void _addNewItemRow({String? initialName, String? initialQty}) {
    _inventoryItems.add({
      'name': TextEditingController(text: initialName ?? ''),
      'qty': TextEditingController(text: initialQty ?? ''),
    });
    setState(() {});
  }

  void _removeItemRow(int index) {
    if (_inventoryItems.length > 1) {
      _inventoryItems[index]['name']?.dispose();
      _inventoryItems[index]['qty']?.dispose();
      _inventoryItems.removeAt(index);
      setState(() {});
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year, 
          picked.month, 
          picked.day, 
          DateTime.now().hour, 
          DateTime.now().minute
        );
        _isToday = false;
      });
    }
  }

  void _setToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _isToday = true;
    });
  }

  String _compileOrderDetails() {
    final buffer = StringBuffer();
    for (var item in _inventoryItems) {
      final name = item['name']?.text.trim() ?? '';
      final qty = item['qty']?.text.trim() ?? '';
      if (name.isNotEmpty) {
        buffer.writeln(qty.isNotEmpty ? '$name $qty' : name);
      }
    }
    return buffer.toString().trim();
  }

  @override
  void dispose() {
    _shopController.dispose();
    _notesController.dispose();
    for (var item in _inventoryItems) {
      item['name']?.dispose();
      item['qty']?.dispose();
    }
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final orderDetails = _compileOrderDetails();
      if (orderDetails.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one item.")));
        return;
      }

      final dateToSave = _isToday ? DateTime.now() : _selectedDate;

      if (widget.task != null) {
        // Edit mode
        final updatedTask = Task(
          id: widget.task!.id,
          shopName: _shopController.text.trim(),
          orderDetails: orderDetails,
          notes: _notesController.text.trim(),
          status: widget.task!.status,
          createdAt: dateToSave,
          partialDetails: widget.task!.partialDetails,
        );
        await DatabaseService().updateTaskDetails(updatedTask);
      } else {
        // Create mode
        final task = Task(
          id: '', 
          shopName: _shopController.text.trim(),
          orderDetails: orderDetails,
          notes: _notesController.text.trim(),
          status: TaskStatus.pending,
          createdAt: dateToSave,
        );
        await DatabaseService().addTask(task);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

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
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // White Card Container
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task != null ? 'Edit Entry' : 'New Entry',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the shop and stock details below.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    
                    // SHOP NAME
                    _buildLabel('SHOP / CLIENT NAME'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _shopController,
                      hint: 'e.g. City Supermarket',
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 24),

                     // DATE SECTION
                    _buildLabel('DELIVERY DATE'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Today Toggle
                        Expanded(
                          child: GestureDetector(
                            onTap: _setToday,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _isToday ? primaryBlue : bgGrey,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _isToday ? primaryBlue : Colors.transparent),
                              ),
                              child: Center(
                                child: Text(
                                  "Today",
                                  style: TextStyle(
                                    color: _isToday ? Colors.white : Colors.grey[600], 
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Custom Date Toggle
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_isToday ? primaryBlue.withOpacity(0.1) : bgGrey,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: !_isToday ? primaryBlue : Colors.transparent),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: !_isToday ? primaryBlue : Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    !_isToday 
                                      ? "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}" 
                                      : "Pick Date",
                                    style: TextStyle(
                                      color: !_isToday ? primaryBlue : Colors.grey[600], 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // INVENTORY LIST HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('INVENTORY LIST'),
                        TextButton.icon(
                          onPressed: () => _addNewItemRow(),
                          icon: Icon(Icons.add, size: 16, color: primaryBlue),
                          label: Text(
                            'ADD ITEM',
                            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: primaryBlue.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // DYNAMIC ITEMS
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _inventoryItems.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgGrey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildTextField(
                                        controller: _inventoryItems[index]['name']!, 
                                        hint: 'Item Name',
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                    if (_inventoryItems.length > 1) 
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                        onPressed: () => _removeItemRow(index),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _inventoryItems[index]['qty']!, 
                                  hint: 'Quantity / Amount',
                                  fillColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // INTERNAL NOTES
                    _buildLabel('INTERNAL NOTES'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      hint: 'Specific instructions, gate codes, or contact person info...',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 48),

                    // ACTIONS
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: primaryBlue.withOpacity(0.4),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.task != null ? 'SAVE CHANGES' : 'CREATE DELIVERY TASK',
                              style: const TextStyle(
                                fontSize: 14, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1,
                                color: Colors.white
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                          ),
                        ),
                      ),
                    ),
                    
                    if (widget.task != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                             // Delete confirmation in Edit Screen
                             showDialog(
                               context: context,
                               builder: (ctx) => AlertDialog(
                                 title: const Text('Delete Task'),
                                 content: Text('Permanently remove "${widget.task!.shopName}"?'),
                                 actions: [
                                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                   ElevatedButton(
                                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                     onPressed: () async {
                                        await DatabaseService().deleteTask(widget.task!.id);
                                        if (mounted) {
                                          Navigator.pop(ctx); // Close dialog
                                          Navigator.pop(context); // Close screen
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Task deleted.')),
                                          );
                                        }
                                     },
                                     child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                   ),
                                 ],
                               ),
                             );
                          },
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          label: const Text(
                            'DELETE ENTRY',
                            style: TextStyle(
                              color: Colors.red, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            // Decorative Static Bottom Nav to match UI perfectly
            Container(
               padding: const EdgeInsets.symmetric(vertical: 16),
               color: Colors.white,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: [
                   _buildNavItem(Icons.home, 'Home', false, () => Navigator.pop(context)),
                   _buildNavItem(Icons.local_shipping, 'Pending', false, () {}),
                   // Fake FAB placeholder
                   Container(
                     height: 56, width: 56,
                     decoration: BoxDecoration(color: primaryBlue.withOpacity(0.5), shape: BoxShape.circle),
                     child: const Icon(Icons.add, color: Colors.white),
                   ),
                   _buildNavItem(Icons.check_circle, 'Delivered', false, () {}),
                   _buildNavItem(Icons.auto_awesome, 'AI Insights', false, () {}),
                 ],
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: labelColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Color? fillColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? bgGrey, // Light grey fill
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: isActive ? primaryBlue : Colors.grey[400]),
          const SizedBox(height: 4),
          Text(
             label, 
             style: TextStyle(
               fontSize: 10, 
               color: isActive ? primaryBlue : Colors.grey[400],
               fontWeight: FontWeight.bold
             )
          ),
        ],
      ),
    );
  }
}
