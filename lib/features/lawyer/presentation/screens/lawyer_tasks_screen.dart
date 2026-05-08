import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/task_model.dart';

class LawyerTasksScreen extends ConsumerStatefulWidget {
  const LawyerTasksScreen({super.key});

  @override
  ConsumerState<LawyerTasksScreen> createState() => _LawyerTasksScreenState();
}

class _LawyerTasksScreenState extends ConsumerState<LawyerTasksScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'All'; // All, Pending, Completed, Today

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final response = await SupabaseService.from('lawyer_tasks')
          .select()
          .eq('lawyer_id', user.id)
          .order('created_at', ascending: false);

      final tasks = (response as List)
          .map((j) => TaskModel.fromJson(j as Map<String, dynamic>))
          .toList();

      setState(() { _tasks = tasks; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('does not exist')
            ? 'Tasks table not set up yet.\nRun the SQL migration in Supabase.'
            : e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleComplete(TaskModel task) async {
    try {
      await SupabaseService.from('lawyer_tasks')
          .update({'is_completed': !task.isCompleted})
          .eq('id', task.id);

      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          _tasks[idx] = task.copyWith(isCompleted: !task.isCompleted);
        }
      });
    } catch (e) {
      _showSnack('Failed to update task', isError: true);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await SupabaseService.from('lawyer_tasks').delete().eq('id', taskId);
      setState(() => _tasks.removeWhere((t) => t.id == taskId));
      _showSnack('Task deleted');
    } catch (e) {
      _showSnack('Failed to delete task', isError: true);
    }
  }

  Future<void> _createTask({
    required String title,
    String? description,
    required TaskPriority priority,
    DateTime? dueDate,
    String? caseTitle,
  }) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    const uuid = Uuid();
    final now = DateTime.now();
    final data = {
      'id': uuid.v4(),
      'lawyer_id': user.id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': false,
      'case_title': caseTitle?.isEmpty == true ? null : caseTitle,
      'created_at': now.toIso8601String(),
    };

    try {
      final response = await SupabaseService.from('lawyer_tasks')
          .insert(data)
          .select()
          .single();

      final newTask = TaskModel.fromJson(response as Map<String, dynamic>);
      setState(() => _tasks.insert(0, newTask));
      _showSnack('Task created');
    } catch (e) {
      _showSnack('Failed to create task: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : SnapLawColors.lawyerPurple,
      duration: const Duration(seconds: 2),
    ));
  }

  List<TaskModel> get _filteredTasks {
    final now = DateTime.now();
    switch (_filter) {
      case 'Pending':
        return _tasks.where((t) => !t.isCompleted).toList();
      case 'Completed':
        return _tasks.where((t) => t.isCompleted).toList();
      case 'Today':
        return _tasks.where((t) =>
          t.dueDate != null &&
          t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day
        ).toList();
      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      appBar: AppBar(
        backgroundColor: SnapLawColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(children: [
          Icon(Icons.task_alt, color: Color(0xFF7B61FF), size: 22),
          SizedBox(width: 8),
          Text('My Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SnapLawColors.lawyerPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            onPressed: _showCreateDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: Column(
          children: [
            // Stats + Filter row
            _buildFilterBar(),
            // Task list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _filteredTasks.isEmpty
                          ? _buildEmpty()
                          : _buildTaskList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: SnapLawColors.lawyerPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterBar() {
    final pending = _tasks.where((t) => !t.isCompleted).length;
    final done = _tasks.where((t) => t.isCompleted).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Summary chips
          Row(children: [
            _SummaryChip(label: 'Total', count: _tasks.length, color: Colors.white24),
            const SizedBox(width: 8),
            _SummaryChip(label: 'Pending', count: pending, color: Colors.orange.withOpacity(0.25)),
            const SizedBox(width: 8),
            _SummaryChip(label: 'Done', count: done, color: Colors.green.withOpacity(0.25)),
          ]),
          const SizedBox(height: 10),
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['All', 'Pending', 'Completed', 'Today'].map((f) =>
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _filter == f
                          ? SnapLawColors.lawyerPurple
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _filter == f
                            ? SnapLawColors.lawyerPurple
                            : Colors.white.withOpacity(0.15),
                      ),
                    ),
                    child: Text(f, style: TextStyle(
                      color: _filter == f ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: _filter == f ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              )
            ).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _TaskCard(
          task: task,
          onToggle: () => _toggleComplete(task),
          onDelete: () => _confirmDelete(task),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_outlined, size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            _filter == 'All' ? 'No tasks yet' : 'No $_filter tasks',
            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Tap + to create a task',
            style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(_error!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  if (_error!.contains('migration'))
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SelectableText(
                        'Run in Supabase SQL Editor:\n\nCREATE TABLE lawyer_tasks (\n  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,\n  lawyer_id UUID,\n  title TEXT NOT NULL,\n  description TEXT,\n  priority TEXT DEFAULT \'medium\',\n  due_date TIMESTAMPTZ,\n  is_completed BOOLEAN DEFAULT FALSE,\n  case_title TEXT,\n  created_at TIMESTAMPTZ DEFAULT NOW()\n);',
                        style: TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadTasks,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: SnapLawColors.lawyerPurple),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SnapLawColors.bgDark,
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${task.title}"?',
          style: TextStyle(color: Colors.white.withOpacity(0.70))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _deleteTask(task.id); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final caseCtrl = TextEditingController();
    TaskPriority priority = TaskPriority.medium;
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: SnapLawColors.bgDark.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.10))),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Icon(Icons.task_alt, color: SnapLawColors.lawyerPurple, size: 22),
                        const SizedBox(width: 8),
                        const Text('New Task', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Title
                      _FieldLabel('Task Title *'),
                      _StyledField(controller: titleCtrl, hint: 'e.g. File FIR documents for Ahmed case'),
                      const SizedBox(height: 12),

                      // Description
                      _FieldLabel('Description (optional)'),
                      _StyledField(controller: descCtrl, hint: 'Add details about this task...', maxLines: 3),
                      const SizedBox(height: 12),

                      // Case
                      _FieldLabel('Related Case (optional)'),
                      _StyledField(controller: caseCtrl, hint: 'e.g. Ahmed vs State'),
                      const SizedBox(height: 12),

                      // Priority
                      _FieldLabel('Priority'),
                      const SizedBox(height: 6),
                      Row(children: TaskPriority.values.map((p) =>
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setModalState(() => priority = p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: priority == p
                                    ? p.color.withOpacity(0.25)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: priority == p ? p.color : Colors.white.withOpacity(0.12),
                                  width: priority == p ? 1.5 : 1,
                                ),
                              ),
                              child: Text(p.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: priority == p ? p.color : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                )),
                            ),
                          ),
                        ))
                      ).toList()),
                      const SizedBox(height: 12),

                      // Due Date
                      _FieldLabel('Due Date (optional)'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            builder: (c, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: ColorScheme.dark(primary: SnapLawColors.lawyerPurple),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setModalState(() => dueDate = picked);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: dueDate != null
                                  ? SnapLawColors.lawyerPurple.withOpacity(0.50)
                                  : Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Row(children: [
                            Icon(Icons.calendar_today,
                              color: dueDate != null ? SnapLawColors.lawyerPurple : Colors.white38,
                              size: 16),
                            const SizedBox(width: 8),
                            Text(
                              dueDate != null
                                  ? DateFormat('EEE, dd MMM yyyy').format(dueDate!)
                                  : 'Select due date',
                              style: TextStyle(
                                color: dueDate != null ? Colors.white : Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                            if (dueDate != null) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setModalState(() => dueDate = null),
                                child: const Icon(Icons.close, color: Colors.white38, size: 16),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (titleCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task title is required')));
                              return;
                            }
                            Navigator.pop(ctx);
                            _createTask(
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                              priority: priority,
                              dueDate: dueDate,
                              caseTitle: caseCtrl.text.trim().isEmpty ? null : caseCtrl.text.trim(),
                            );
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SnapLawColors.lawyerPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({required this.task, required this.onToggle, required this.onDelete});

  bool get _isOverdue =>
      task.dueDate != null &&
      task.dueDate!.isBefore(DateTime.now()) &&
      !task.isCompleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: task.isCompleted
                    ? Colors.white.withOpacity(0.08)
                    : _isOverdue
                        ? Colors.red.withOpacity(0.35)
                        : task.priority.color.withOpacity(0.30),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24, height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? SnapLawColors.lawyerPurple
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: task.isCompleted
                            ? SnapLawColors.lawyerPurple
                            : Colors.white38,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: task.isCompleted
                                  ? Colors.white38
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        // Priority badge
                        if (!task.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: task.priority.color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: task.priority.color.withOpacity(0.40)),
                            ),
                            child: Text(task.priority.label,
                              style: TextStyle(
                                color: task.priority.color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              )),
                          ),
                      ]),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, height: 1.4)),
                      ],
                      const SizedBox(height: 6),
                      Row(children: [
                        if (task.caseTitle != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: SnapLawColors.lawyerPurple.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.folder_outlined, size: 11, color: SnapLawColors.lawyerPurple),
                              const SizedBox(width: 3),
                              Text(task.caseTitle!,
                                style: TextStyle(color: SnapLawColors.lawyerPurple, fontSize: 10)),
                            ]),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (task.dueDate != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.calendar_today,
                              size: 11,
                              color: _isOverdue ? Colors.red : Colors.white38),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('dd MMM').format(task.dueDate!),
                              style: TextStyle(
                                color: _isOverdue ? Colors.red : Colors.white38,
                                fontSize: 11,
                                fontWeight: _isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (_isOverdue)
                              const Text(' · Overdue',
                                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ]),
                      ]),
                    ],
                  ),
                ),

                // Delete
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.white.withOpacity(0.30)),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11)),
      ]),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _StyledField({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.30), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F1535).withOpacity(0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: SnapLawColors.lawyerPurple.withOpacity(0.60)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
