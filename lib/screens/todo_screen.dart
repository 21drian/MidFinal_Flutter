import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

enum _TodoFilter {
  all,
  pending,
  today,
  done,
}

class _TodoColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFFE6532E);
  static const primaryDark = Color(0xFFD94A28);
  static const primaryLight = Color(0xFFF6C06F);
  static const textDark = Color(0xFF2D2D2D);
  static const mutedText = Color(0xFF8E8E8E);
  static const labelColor = Color(0xFF8B4D07);
  static const border = Color(0xFFF2BE73);
  static const softBorder = Color(0xFFF0E4D4);
  static const fieldFill = Color(0xFFFFFCF9);
  static const chipFill = Color(0xFFFFF6E8);
  static const danger = Color(0xFFD32F2F);
  static const green = Color(0xFF4CAF50);
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _todoService = TodoService();
  _TodoFilter _selectedFilter = _TodoFilter.all;

  Future<void> _openAddTask() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditTodoScreen(),
      ),
    );
  }

  Future<void> _openEditTask(Todo todo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTodoScreen(todo: todo),
      ),
    );
  }

  Future<void> _confirmDelete(Todo todo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Delete task?',
            style: TextStyle(
              color: _TodoColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${todo.title}"?',
            style: const TextStyle(color: _TodoColors.mutedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _TodoColors.mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _TodoColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _todoService.deleteTodo(todo.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted.'),
          backgroundColor: _TodoColors.primary,
        ),
      );
    }
  }

  List<Todo> _applyFilter(List<Todo> todos) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case _TodoFilter.all:
        return todos;
      case _TodoFilter.pending:
        return todos.where((todo) => !todo.isDone).toList();
      case _TodoFilter.today:
        return todos.where((todo) {
          final deadline = todo.deadline;
          if (deadline == null) return false;
          return _isSameDay(deadline, now);
        }).toList();
      case _TodoFilter.done:
        return todos.where((todo) => todo.isDone).toList();
    }
  }

  List<Todo> _sortPending(List<Todo> todos) {
    final sorted = [...todos];

    sorted.sort((a, b) {
      final aDeadline = a.deadline;
      final bDeadline = b.deadline;

      if (aDeadline == null && bDeadline == null) {
        return b.createdAt.compareTo(a.createdAt);
      }

      if (aDeadline == null) return 1;
      if (bDeadline == null) return -1;

      return aDeadline.compareTo(bDeadline);
    });

    return sorted;
  }

  List<Todo> _sortCompleted(List<Todo> todos) {
    final sorted = [...todos];

    sorted.sort((a, b) {
      final aDate = a.completedAt ?? a.updatedAt;
      final bDate = b.completedAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return sorted;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _filterLabel(_TodoFilter filter) {
    switch (filter) {
      case _TodoFilter.all:
        return 'All';
      case _TodoFilter.pending:
        return 'Pending';
      case _TodoFilter.today:
        return 'Today';
      case _TodoFilter.done:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TodoColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTask,
        backgroundColor: _TodoColors.primary,
        elevation: 7,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Todo>>(
          stream: _todoService.getTodos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _TodoColors.primary),
              );
            }

            if (snapshot.hasError) {
              return _ErrorView(message: snapshot.error.toString());
            }

            final todos = snapshot.data ?? [];
            final pendingCount = todos.where((todo) => !todo.isDone).length;
            final completedCount = todos.where((todo) => todo.isDone).length;

            final filteredTodos = _applyFilter(todos);
            final pendingTodos = _sortPending(
              filteredTodos.where((todo) => !todo.isDone).toList(),
            );
            final completedTodos = _sortCompleted(
              filteredTodos.where((todo) => todo.isDone).toList(),
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: _Header(
                      pendingCount: pendingCount,
                      completedCount: completedCount,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 23, 22, 0),
                    child: _FilterRow(
                      selectedFilter: _selectedFilter,
                      labelBuilder: _filterLabel,
                      onSelected: (filter) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  ),
                ),
                if (filteredTodos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(selectedFilter: _selectedFilter),
                  )
                else ...[
                  if (pendingTodos.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'PENDING'),
                    ),
                  SliverList.builder(
                    itemCount: pendingTodos.length,
                    itemBuilder: (context, index) {
                      final todo = pendingTodos[index];

                      return _TodoListItem(
                        todo: todo,
                        onToggle: () {
                          _todoService.toggleDone(todo.id, todo.isDone);
                        },
                        onEdit: () => _openEditTask(todo),
                        onDelete: () => _confirmDelete(todo),
                      );
                    },
                  ),
                  if (completedTodos.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: _SectionTitle(title: 'COMPLETED'),
                    ),
                  SliverList.builder(
                    itemCount: completedTodos.length,
                    itemBuilder: (context, index) {
                      final todo = completedTodos[index];

                      return _TodoListItem(
                        todo: todo,
                        onToggle: () {
                          _todoService.toggleDone(todo.id, todo.isDone);
                        },
                        onEdit: () => _openEditTask(todo),
                        onDelete: () => _confirmDelete(todo),
                      );
                    },
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 95),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pendingCount,
    required this.completedCount,
  });

  final int pendingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'My Tasks',
                style: TextStyle(
                  color: _TodoColors.textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$pendingCount pending · $completedCount completed',
                style: const TextStyle(
                  color: _TodoColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: _TodoColors.primaryLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'AP',
            style: TextStyle(
              color: _TodoColors.labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selectedFilter,
    required this.labelBuilder,
    required this.onSelected,
  });

  final _TodoFilter selectedFilter;
  final String Function(_TodoFilter filter) labelBuilder;
  final ValueChanged<_TodoFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _TodoFilter.values.map((filter) {
        final selected = selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _TodoColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? _TodoColors.primary : _TodoColors.border,
                  width: 1.1,
                ),
              ),
              child: Text(
                labelBuilder(filter),
                style: TextStyle(
                  color: selected ? Colors.white : _TodoColors.labelColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 27, 18, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _TodoColors.labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(
              color: _TodoColors.softBorder,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoListItem extends StatelessWidget {
  const _TodoListItem({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(todo.priority);
    final priorityText = _capitalize(todo.priority);

    final dateText = todo.isDone
        ? 'Completed ${_formatShortDate(todo.completedAt ?? todo.updatedAt)}'
        : todo.deadline == null
            ? 'No due date'
            : 'Due ${_formatShortDate(todo.deadline!)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _TodoColors.softBorder,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DoneBox(
              isDone: todo.isDone,
              onTap: onToggle,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _TodoColors.textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$priorityText · $dateText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _TodoColors.labelColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (todo.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        todo.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _TodoColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _SubjectBadge(subject: todo.subject),
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 8,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 19,
                    color: _TodoColors.mutedText,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFB3261E);
      case 'medium':
        return const Color(0xFF9B6A12);
      case 'low':
        return _TodoColors.green;
      default:
        return _TodoColors.mutedText;
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }
}

class _DoneBox extends StatelessWidget {
  const _DoneBox({
    required this.isDone,
    required this.onTap,
  });

  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 23,
        height: 23,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: isDone ? _TodoColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDone ? _TodoColors.primary : _TodoColors.border,
            width: 1.7,
          ),
        ),
        child: isDone
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 17,
              )
            : null,
      ),
    );
  }
}

class _SubjectBadge extends StatelessWidget {
  const _SubjectBadge({required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context) {
    final displaySubject = subject.trim().isEmpty ? 'N/A' : subject.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _TodoColors.chipFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _TodoColors.border,
          width: 1,
        ),
      ),
      child: Text(
        displaySubject,
        style: const TextStyle(
          color: _TodoColors.labelColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.selectedFilter,
  });

  final _TodoFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    String message = 'No tasks yet.\nTap + to add one.';

    if (selectedFilter == _TodoFilter.pending) {
      message = 'No pending tasks.';
    } else if (selectedFilter == _TodoFilter.today) {
      message = 'No tasks due today.';
    } else if (selectedFilter == _TodoFilter.done) {
      message = 'No completed tasks yet.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 70,
              color: _TodoColors.primary.withOpacity(0.20),
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _TodoColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Text(
          'Error: $message',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _TodoColors.danger,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class AddEditTodoScreen extends StatefulWidget {
  const AddEditTodoScreen({
    super.key,
    this.todo,
  });

  final Todo? todo;

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _todoService = TodoService();

  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();

  DateTime? _deadline;
  String _priority = 'high';
  bool _reminderEnabled = true;
  bool _isSaving = false;

  bool get _isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();

    final todo = widget.todo;

    if (todo != null) {
      _titleCtrl.text = todo.title;
      _subjectCtrl.text = todo.subject;
      _notesCtrl.text = todo.notes;
      _deadline = todo.deadline;
      _priority = todo.priority;
      _reminderEnabled = todo.reminderEnabled;
      _deadlineCtrl.text =
          _deadline == null ? '' : _formatFullDate(_deadline!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _notesCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _TodoColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _TodoColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _deadline = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
      );
      _deadlineCtrl.text = _formatFullDate(_deadline!);
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEdit) {
        await _todoService.updateTodo(
          widget.todo!.id,
          title: _titleCtrl.text,
          subject: _subjectCtrl.text.trim(),
          deadline: _deadline,
          priority: _priority,
          notes: _notesCtrl.text,
          reminderEnabled: _reminderEnabled,
        );
      } else {
        await _todoService.addTodo(
          title: _titleCtrl.text,
          subject: _subjectCtrl.text.trim(),
          deadline: _deadline,
          priority: _priority,
          notes: _notesCtrl.text,
          reminderEnabled: _reminderEnabled,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save task: $e'),
          backgroundColor: _TodoColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _TodoColors.mutedText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _TodoColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _TodoColors.border,
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _TodoColors.border,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _TodoColors.primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _TodoColors.danger,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: _TodoColors.danger,
          width: 1.4,
        ),
      ),
      errorStyle: const TextStyle(
        color: _TodoColors.danger,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _TodoColors.labelColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TodoColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _isEdit ? 'Edit Task' : 'Add New Task',
          style: const TextStyle(
            color: _TodoColors.textDark,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _TodoColors.primary,
                      disabledBackgroundColor:
                          _TodoColors.primary.withOpacity(0.50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.3,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save Task' : 'Add Task',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _TodoColors.labelColor,
                      side: const BorderSide(
                        color: _TodoColors.border,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 23, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Fill in task details below',
                  style: TextStyle(
                    color: _TodoColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 27),

                _buildLabel('TASK TITLE'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _titleCtrl,
                  cursorColor: _TodoColors.primary,
                  style: const TextStyle(
                    color: _TodoColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Enter task title...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Task title is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _buildLabel('SUBJECT'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _subjectCtrl,
                  cursorColor: _TodoColors.primary,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: _TodoColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Enter subject code, example: ITC 130',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subject is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _buildLabel('DEADLINE'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _deadlineCtrl,
                  readOnly: true,
                  onTap: _pickDeadline,
                  cursorColor: _TodoColors.primary,
                  style: const TextStyle(
                    color: _TodoColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Select date...',
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _TodoColors.primary,
                    ),
                  ),
                  validator: (_) {
                    if (_deadline == null) {
                      return 'Deadline is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                _buildLabel('PRIORITY LEVEL'),
                const SizedBox(height: 10),
                _PrioritySelector(
                  selectedPriority: _priority,
                  onChanged: (priority) {
                    setState(() => _priority = priority);
                  },
                ),

                const SizedBox(height: 20),

                _buildLabel('NOTES (OPTIONAL)'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _notesCtrl,
                  cursorColor: _TodoColors.primary,
                  maxLines: 5,
                  style: const TextStyle(
                    color: _TodoColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Add notes...',
                  ),
                ),

                const SizedBox(height: 17),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: _TodoColors.fieldFill,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _TodoColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set reminder',
                              style: TextStyle(
                                color: _TodoColors.textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Get notified before deadline',
                              style: TextStyle(
                                color: _TodoColors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        activeColor: _TodoColors.primary,
                        activeTrackColor:
                            _TodoColors.primary.withOpacity(0.25),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFE8E8E8),
                        onChanged: (value) {
                          setState(() => _reminderEnabled = value);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatFullDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selectedPriority,
    required this.onChanged,
  });

  final String selectedPriority;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const priorities = ['high', 'medium', 'low'];

    return Row(
      children: priorities.map((priority) {
        final selected = selectedPriority == priority;

        return Padding(
          padding: const EdgeInsets.only(right: 9),
          child: GestureDetector(
            onTap: () => onChanged(priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFF1F0) : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFB3261E)
                      : const Color(0xFFE8E8E8),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (priority == 'high') ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB3261E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    _capitalize(priority),
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF7A1E19)
                          : _TodoColors.mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}