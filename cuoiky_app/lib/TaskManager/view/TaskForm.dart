import 'package:flutter/material.dart';
import '../model/Taskdb.dart';
import '../api/UserAPIService.dart';
import '../model/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskForm extends StatefulWidget {
  final Taskdb? task;
  final Function(Taskdb) onSave;

  const TaskForm({super.key, this.task, required this.onSave});

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _attachmentsController = TextEditingController();

  final _statusList = ['to do', 'in progress', 'done', 'cancelled'];
  final _priorityList = [3, 2, 1];

  DateTime? _dueDate;
  String _selectedStatus = 'to do';
  int _selectedPriority = 2;
  String? _assignedTo;
  bool _isCompleted = false;

  List<User> _userList = [];
  String? _currentUserName;
  String? _currentUserRole;

  bool get isAdmin => (_currentUserRole ?? '').trim().toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserName = prefs.getString('accountId');
    _currentUserRole = prefs.getString('role') ?? 'user';

    final allUsers = await UserAPIService.instance.getAllUsers();

    setState(() {
      _userList = allUsers.where((u) => u.role.trim().toLowerCase() == 'user').toList();

      if (widget.task != null) {
        final t = widget.task!;
        _titleController.text = t.title;
        _descriptionController.text = t.description;
        _categoryController.text = t.category ?? '';
        _attachmentsController.text = t.attachments?.join(',') ?? '';

        final legacyStatus = t.status.toLowerCase();
        switch (legacyStatus) {
          case 'open':
            _selectedStatus = 'to do';
            break;
          case 'review':
            _selectedStatus = 'done';
            break;
          case 'complete':
            _selectedStatus = 'cancelled';
            break;
          default:
            _selectedStatus = _statusList.contains(legacyStatus) ? legacyStatus : 'to do';
        }

        _selectedPriority = _priorityList.contains(t.priority) ? t.priority : 2;
        _dueDate = t.dueDate;
        _assignedTo = t.assignedTo;
        _isCompleted = t.completed;
      } else {
        _assignedTo = isAdmin ? null : _currentUserName;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _attachmentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được người dùng hiện tại')),
      );
      return;
    }

    if (isAdmin && (_assignedTo == null || _assignedTo!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người nhận công việc')),
      );
      return;
    }

    final now = DateTime.now();

    final updatedTask = widget.task?.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      priority: _selectedPriority,
      dueDate: _dueDate,
      updatedAt: now,
      assignedTo: isAdmin ? _assignedTo : _currentUserName,
      category: _categoryController.text.trim(),
      attachments: _attachmentsController.text.trim().isNotEmpty
          ? _attachmentsController.text.trim().split(',').map((e) => e.trim()).toList()
          : [],
      completed: _isCompleted,
    ) ??
        Taskdb(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _selectedStatus,
          priority: _selectedPriority,
          dueDate: _dueDate,
          createdAt: now,
          updatedAt: now,
          createdBy: _currentUserName!,
          assignedTo: isAdmin ? _assignedTo : _currentUserName,
          category: _categoryController.text.trim(),
          attachments: _attachmentsController.text.trim().isNotEmpty
              ? _attachmentsController.text.trim().split(',').map((e) => e.trim()).toList()
              : [],
          completed: _isCompleted,
        );

    await widget.onSave(updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEdit ? 'Chỉnh sửa Công Việc' : 'Tạo Công Việc Mới',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.orangeAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.orangeAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildFormContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _buildTextField(_titleController, 'Tiêu đề công việc', isRequired: true),
          const SizedBox(height: 12),
          _buildTextField(_descriptionController, 'Mô tả', maxLines: 3),
          const SizedBox(height: 12),
          _buildDropdownStatus(),
          const SizedBox(height: 12),
          _buildDropdownPriority(),
          const SizedBox(height: 12),
          _buildTextField(_categoryController, 'Phân loại'),
          const SizedBox(height: 12),
          _buildTextField(_attachmentsController, 'Tệp đính kèm (link, cách nhau bằng dấu phẩy)'),
          const SizedBox(height: 12),
          if (isAdmin)
            _buildAssignDropdown()
          else
            Text('Phân công cho: ($_currentUserName)'),
          const SizedBox(height: 12),
          _buildDatePicker(),
          CheckboxListTile(
            title: const Text('Đánh dấu là hoàn thành'),
            value: _isCompleted,
            onChanged: (val) => setState(() => _isCompleted = val ?? false),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3300),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              widget.task != null ? 'Cập nhật' : 'Tạo mới',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? (val) => val == null || val.isEmpty ? 'Vui lòng nhập $label' : null
          : null,
    );
  }

  Widget _buildDropdownStatus() {
    return DropdownButtonFormField<String>(
      value: _statusList.contains(_selectedStatus) ? _selectedStatus : null,
      items: _statusList.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text(s),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedStatus = val!),
      decoration: const InputDecoration(
        labelText: 'Trạng thái',
        border: OutlineInputBorder(),
      ),
      validator: (val) => val == null ? 'Vui lòng chọn trạng thái' : null,
    );
  }

  Widget _buildDropdownPriority() {
    return DropdownButtonFormField<int>(
      value: _priorityList.contains(_selectedPriority) ? _selectedPriority : 2,
      items: _priorityList.map((level) {
        String text;
        switch (level) {
          case 3:
            text = 'Cao';
            break;
          case 2:
            text = 'Trung bình';
            break;
          case 1:
            text = 'Thấp';
            break;
          default:
            text = 'Không xác định';
        }
        return DropdownMenuItem(
          value: level,
          child: Text(text),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedPriority = val!),
      decoration: const InputDecoration(
        labelText: 'Độ ưu tiên',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAssignDropdown() {
    return DropdownButtonFormField<String>(
      value: _userList.any((u) => u.id == _assignedTo) ? _assignedTo : null,
      items: _userList.map((u) {
        return DropdownMenuItem<String>(
          value: u.id,
          child: Text(u.username),
        );
      }).toList(),
      onChanged: (val) => setState(() => _assignedTo = val),
      decoration: const InputDecoration(
        labelText: 'Phân Công Cho',
        border: OutlineInputBorder(),
      ),
      validator: (val) =>
      isAdmin && (val == null || val.isEmpty) ? 'Vui lòng chọn người nhận' : null,
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text(
        _dueDate == null
            ? 'Deadline'
            : 'Deadline: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => _dueDate = picked);
      },
    );
  }
}