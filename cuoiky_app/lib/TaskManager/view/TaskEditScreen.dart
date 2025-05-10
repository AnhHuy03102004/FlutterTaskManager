import 'package:flutter/material.dart';
import '../model/Taskdb.dart';
import '../api/TaskAPIService.dart';
import 'TaskForm.dart';

class TaskEditScreen extends StatelessWidget {
  final Taskdb task;

  const TaskEditScreen({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TaskForm(
      task: task,
      onSave: (updatedTask) async {
        await TaskAPIService.instance.updateTask(updatedTask);
        if (context.mounted) {
          Navigator.pop(context, updatedTask);
        }
      },
    );
  }
}
