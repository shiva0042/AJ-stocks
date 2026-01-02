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
  // Each item is {brand: String, name: Controller, qty: Controller, custom: Controller}
  final List<Map<String, dynamic>> _inventoryItems = [];

  bool _isLoading = false;

  // Colors
  final Color primaryBlue = const Color(0xFF4C4DDC);
  final Color bgGrey = const Color(0xFFF4F6F8);
  final Color labelColor = const Color(0xFF8A94A6);

  // Date Selection
  bool _isToday = true;
  DateTime _selectedDate = DateTime.now();

  // Status Selection
  TaskStatus _status = TaskStatus.pending;

  // Brand Options
  final List<String> _brands = ['Prestine', 'Frozen', 'Milky mist', 'Shakthi', 'Others'];
  
  // Note: Global brand state is removed in favor of per-row brands

  @override
  void initState() {
    super.initState();
    _shopController = TextEditingController(text: widget.task?.shopName ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    
    _initInventory();
    _initDate();
    if (widget.task != null) {
      _status = widget.task!.status;
    }
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
      // Logic for multi-brand parsing: expects "Brand - Name Qty" or "Brand: Name Qty"
      final lines = widget.task!.orderDetails.split('\n');
      for (var line in lines) {
         if (line.trim().isEmpty) continue;
         
         String brandFound = 'Others';
         String namePart = line;
         
         // Attempt to identify brand from line start
         for (var b in _brands) {
           if (b == 'Others') continue;
           if (line.trim().startsWith('$b - ')) {
             brandFound = b;
             namePart = line.replaceFirst('$b - ', '');
             break;
           }
         }

         _addNewItemRow(
           initialBrand: brandFound,
           initialName: namePart,
           initialCustomBrand: brandFound == 'Others' && line.contains(' - ') ? line.split(' - ').first : null
         );
      }
    } else {
      _addNewItemRow();
    }
  }

  void _addNewItemRow({String? initialBrand, String? initialName, String? initialQty, String? initialCustomBrand}) {
    _inventoryItems.add({
      'brand': initialBrand ?? 'Prestine', // Store brand string directly
      'name': TextEditingController(text: initialName ?? ''),
      'qty': TextEditingController(text: initialQty ?? ''),
      'custom': TextEditingController(text: initialCustomBrand ?? ''),
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

  @override
  void dispose() {
    _shopController.dispose();
    _notesController.dispose();
    for (var item in _inventoryItems) {
      if (item['name'] is TextEditingController) (item['name'] as TextEditingController).dispose();
      if (item['qty'] is TextEditingController) (item['qty'] as TextEditingController).dispose();
      if (item['custom'] is TextEditingController) (item['custom'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  String _compileOrderDetails() {
    final buffer = StringBuffer();
    for (var item in _inventoryItems) {
      final brandVal = item['brand'] as String? ?? 'Prestine';
      final customB = (item['custom'] as TextEditingController?)?.text.trim() ?? '';
      final name = (item['name'] as TextEditingController?)?.text.trim() ?? '';
      final qty = (item['qty'] as TextEditingController?)?.text.trim() ?? '';
      
      final actualBrand = brandVal == 'Others' ? customB : brandVal;
      
      if (name.isNotEmpty) {
        buffer.writeln('$actualBrand - $name $qty');
      }
    }
    return buffer.toString().trim();
  }

  List<String> _compileBrands() {
    final Set<String> uniqueBrands = {};
    for (var item in _inventoryItems) {
      final brandVal = item['brand'] as String? ?? 'Prestine';
      final customB = (item['custom'] as TextEditingController?)?.text.trim() ?? '';
      uniqueBrands.add(brandVal == 'Others' ? customB : brandVal);
    }
    return uniqueBrands.where((b) => b.isNotEmpty).toList();
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
      final brandsList = _compileBrands();
      final brandString = brandsList.join(', ');

      if (widget.task != null) {
        // Edit mode
        final updatedTask = Task(
          id: widget.task!.id,
          shopName: _shopController.text.trim(),
          brand: brandString,
          orderDetails: orderDetails,
          notes: _notesController.text.trim(),
          status: _status,
          createdAt: dateToSave,
          partialDetails: widget.task!.partialDetails,
        );
        await DatabaseService().updateTaskDetails(updatedTask);
      } else {
        // Create mode
        final task = Task(
          id: '', 
          shopName: _shopController.text.trim(),
          brand: brandString,
          orderDetails: orderDetails,
          notes: _notesController.text.trim(),
          status: _status,
          createdAt: dateToSave,
        );
        await DatabaseService().addTask(task);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _confirmDelete() {
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
          if (widget.task != null)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: 'Delete Task',
            ),
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
                    
                    // STATUS & PRIORITY SECTION
                    _buildLabel('STATUS & PRIORITY'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TaskStatus>(
                          value: _status,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: primaryBlue),
                          items: TaskStatus.values.map((status) {
                            String label;
                            Color color;
                            switch (status) {
                              case TaskStatus.urgent: label = 'Urgent Priority'; color = Colors.red; break;
                              case TaskStatus.pending: label = 'Standard (Pending)'; color = Colors.blueGrey; break;
                              case TaskStatus.partial: label = 'Partial / Split'; color = Colors.orange; break;
                              case TaskStatus.delivered: label = 'Delivered'; color = Colors.green; break;
                            }
                            return DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                  const SizedBox(width: 12),
                                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
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
                        final item = _inventoryItems[index];
                        final currentBrand = item['brand'] as String;
                        final nameCtrl = item['name'] as TextEditingController;
                        final qtyCtrl = item['qty'] as TextEditingController;
                        final customCtrl = item['custom'] as TextEditingController;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgGrey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Brand Dropdown (Full Width on its own row for clarity)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentBrand,
                                      isExpanded: true,
                                      icon: const Icon(Icons.business_rounded, size: 20, color: Colors.blueGrey),
                                      hint: const Text("Select Brand"),
                                      items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _inventoryItems[index]['brand'] = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                if (currentBrand == 'Others') ...[
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: customCtrl,
                                    hint: 'Type Custom Brand Name',
                                    fillColor: Colors.white,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                // Item Name and Quantity Row
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildTextField(
                                        controller: nameCtrl, 
                                        hint: 'Product Name',
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: _buildTextField(
                                        controller: qtyCtrl, 
                                        hint: 'Qty',
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                    if (_inventoryItems.length > 1) 
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 24),
                                        onPressed: () => _removeItemRow(index),
                                      )
                                  ],
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
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'DISCARD CHANGES',
                          style: TextStyle(
                            color: Colors.grey[500], 
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    
                    if (widget.task != null) ...[
                      const SizedBox(height: 16),
                      Center(
                            child: TextButton.icon(
                            onPressed: _confirmDelete,
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
