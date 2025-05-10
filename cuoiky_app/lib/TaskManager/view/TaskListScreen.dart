import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/Taskdb.dart';
import '../api/TaskAPIService.dart';
import 'TaskForm.dart';
import 'TaskLoginScreen.dart';
import 'TaskDetailScreen.dart';
import 'TaskListItem.dart';

class TaskListScreen extends StatefulWidget {
  final Function? onLogout;

  const TaskListScreen({this.onLogout, Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedTaskIds = {};
  bool _selectionMode = false;
  String? _userId;
  String? _username;
  String? _userRole;

  List<Taskdb> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndRefresh();
  }

  // Tải thông tin người dùng từ SharedPreferences và gọi API để lấy task
  Future<void> _loadUserAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('accountId');
    _username = prefs.getString('username');
    _userRole = prefs.getString('role');
    _refreshTasks();
  }

  // Làm mới danh sách task theo vai trò
  void _refreshTasks() async {
    if (_userRole == 'admin') {
      final tasks = await TaskAPIService.instance.getAllTasks();
      tasks.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
      setState(() {
        _tasks = tasks;
        _selectedTaskIds.clear();
        _selectionMode = false;
      });
    } else if (_userId != null) {
      final tasks = await TaskAPIService.instance.getTasksByUser(_userId!);
      tasks.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
      setState(() {
        _tasks = tasks;
        _selectedTaskIds.clear();
        _selectionMode = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Chuyển đổi chế độ chọn task (multi-select)
  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _selectionMode = false;
      } else {
        _selectedTaskIds.add(taskId);
        _selectionMode = true;
      }
    });
  }

  // Xóa các task đã chọn
  void _deleteSelectedTasks() async {
    for (final id in _selectedTaskIds) {
      await TaskAPIService.instance.deleteTask(id);
    }
    _refreshTasks();
  }

  // Đăng xuất
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TaskLoginScreen()),
          (route) => false,
    );
  }

  // Hộp thoại xác nhận đăng xuất
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.orangeAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        title: Text(
          _selectionMode ? 'Đã chọn: ${_selectedTaskIds.length}' : 'Xin chào, ${_username ?? 'người dùng'}',
          style: const TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
        actions: [
          if (_selectionMode)
            IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _deleteSelectedTasks)
          else ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'logout') _showLogoutDialog();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Đăng xuất'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                hintStyle: const TextStyle(color: Colors.white),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _refreshTasks();
                  },
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) async {
                if (_userId != null) {
                  try {
                    if (value.isEmpty) {
                      _refreshTasks();
                    } else {
                      final results = _userRole == 'admin'
                          ? await TaskAPIService.instance.searchAllTasks(value)
                          : await TaskAPIService.instance.searchTasks(_userId!, value);
                      results.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
                      setState(() {
                        _tasks = results;
                      });
                    }
                  } catch (e) {
                    debugPrint('Search error: $e');
                  }
                }
              },
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
        child: _tasks.isEmpty
            ? const Center(
          child: Text(
            'Không có công việc',
            style: TextStyle(color: Colors.white),
          ),
        )
            : ListView.builder(
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return TaskListItem(
              task: task,
              onEdit: () async {
                final updatedTask = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskForm(
                      task: task.copyWith(),
                      onSave: (updatedTask) async {
                        await TaskAPIService.instance.updateTask(updatedTask);
                        setState(() {
                          final idx = _tasks.indexWhere((t) => t.id == updatedTask.id);
                          if (idx != -1) _tasks[idx] = updatedTask;
                        });
                      },
                    ),
                  ),
                );
              },
              onDelete: () async {
                await TaskAPIService.instance.deleteTask(task.id);
                _refreshTasks();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskForm(
                onSave: (task) async {
                  await TaskAPIService.instance.createTask(task);
                  Navigator.pop(context, task);
                },
              ),
            ),
          );
          if (newTask != null) {
            setState(() {
              _tasks.add(newTask);
              _tasks.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
