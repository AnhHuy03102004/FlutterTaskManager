import 'package:flutter/material.dart';
import '../model/Taskdb.dart';
import 'TaskDetailScreen.dart';

class TaskListItem extends StatelessWidget {
  final Taskdb task;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onTap;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onDelete,
    required this.onEdit,
    this.onTap,
  }) : super(key: key);

  Color _priorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.redAccent; // Đổi sang màu hồng nhạt
      case 2:
        return Colors.yellow; // Cam nhạt (giữ nguyên)
      default:
        return Colors.green; // Vàng nhạt để đồng bộ màu gradient
    }
  }

  Color _textColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _priorityColor(task.priority);
    final textColor = _textColor(bgColor);

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            task.title.isNotEmpty ? task.title[0].toUpperCase() : '?',
            style: TextStyle(color: bgColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(task.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(
          task.description.length > 50
              ? '${task.description.substring(0, 50)}...'
              : task.description,
          style: TextStyle(color: textColor.withAlpha(200)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              color: Colors.blue, // Màu cam để đồng bộ với giao diện
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.black, // Màu hồng để đồng bộ với giao diện
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xác nhận xoá'),
                    content: const Text('Bạn có chắc muốn xoá công việc này không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Huỷ'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Xoá', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        onTap: onTap ??
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
              );
            },
      ),
    );
  }
}