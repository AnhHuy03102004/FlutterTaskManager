import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/Taskdb.dart';
import '../api/UserAPIService.dart';
import '../model/User.dart';

class TaskDetailScreen extends StatefulWidget {
  final Taskdb task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String? _assignedToUsername;
  String? _createdByUsername;
  final formatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadUsernames();
  }

  Future<void> _loadUsernames() async {
    try {
      if (widget.task.assignedTo != null) {
        final assignedUser = await UserAPIService.instance.getUserById(widget.task.assignedTo!);
        setState(() {
          _assignedToUsername = assignedUser?.username ?? 'Không rõ';
        });
      }

      final creatorUser = await UserAPIService.instance.getUserById(widget.task.createdBy);
      setState(() {
        _createdByUsername = creatorUser?.username ?? 'Không rõ';
      });
    } catch (e) {
      setState(() {
        _assignedToUsername = 'Không rõ';
        _createdByUsername = 'Không rõ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.redAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.redAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white.withOpacity(0.95),
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.task.title,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _infoRow(Icons.calendar_today, 'Tạo lúc: ${formatter.format(widget.task.createdAt)}'),
                    _infoRow(Icons.update, 'Cập nhật: ${formatter.format(widget.task.updatedAt)}'),
                    _infoRow(Icons.info_outline, 'Trạng thái: ${widget.task.status}'),
                    _infoRow(Icons.priority_high, 'Ưu tiên: ${_priorityText(widget.task.priority)}',
                        color: _priorityColor(widget.task.priority)),
                    if (widget.task.dueDate != null)
                      _infoRow(Icons.calendar_month, 'Hạn chót: ${formatter.format(widget.task.dueDate!)}'),
                    _infoRow(Icons.check_circle_outline,
                        'Hoàn thành: ${widget.task.completed ? "✔ Đã Hoàn Thành" : "✘ Chưa Hoàn Thành"}'),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.task.description,
                        style: const TextStyle(fontSize: 18, color: Colors.blueAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.task.category != null && widget.task.category!.isNotEmpty)
                      Chip(
                        label: Text(widget.task.category!, style: const TextStyle(color: Colors.white)),
                        backgroundColor: const Color(0xFFFF758C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Người tạo: ${_createdByUsername ?? "Đang tải..."}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Giao cho: ${_assignedToUsername ?? "Đang tải..."}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.task.attachments != null && widget.task.attachments!.isNotEmpty) ...[
                      const Text(
                        'Tệp đính kèm:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: widget.task.attachments!
                            .map((file) => Text('- $file', style: const TextStyle(color: Colors.blueAccent)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: Colors.redAccent),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 18, color: color ?? Colors.black87)),
      ],
    ),
  );

  String _priorityText(int value) =>
      value == 1 ? 'Thấp' : value == 2 ? 'Trung bình' : 'Cao';

  Color _priorityColor(int value) {
    return value == 3
        ? Colors.deepOrange
        : value == 2
        ? Colors.amber
        : Colors.lightGreen;
  }
}
