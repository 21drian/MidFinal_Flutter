import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _primary = Color(0xFFE6532E);
  static const _border = Color(0xFFF2BE73);
  static const _mutedText = Color(0xFF8E8E8E);

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _DashboardScreen(
          onOpenTasks: () => setState(() => _currentIndex = 1),
          onOpenGrades: () => setState(() => _currentIndex = 2),
        );
      case 1:
        return const TodoScreen();
      case 2:
        return const GradesScreen();
      case 3:
        return const _ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildCurrentPage(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: _border,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: _primary,
          unselectedItemColor: _mutedText,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Grades',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppColors {
  static const background = Color(0xFFFFFFFF);
  static const primary = Color(0xFFE6532E);
  static const primaryLight = Color(0xFFF6C06F);
  static const textDark = Color(0xFF2D2D2D);
  static const mutedText = Color(0xFF8E8E8E);
  static const labelColor = Color(0xFF8B4D07);
  static const border = Color(0xFFF2BE73);
  static const softBorder = Color(0xFFF0E4D4);
  static const chipFill = Color(0xFFFFF6E8);
  static const green = Color(0xFF2E7D32);
  static const danger = Color(0xFFE53935);
}

class _DashboardScreen extends StatefulWidget {
  const _DashboardScreen({
    required this.onOpenTasks,
    required this.onOpenGrades,
  });

  final VoidCallback onOpenTasks;
  final VoidCallback onOpenGrades;

  @override
  State<_DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<_DashboardScreen> {
  final _apiService = InstructorApiService();
  final _todoService = TodoService();

  late Future<StudentDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    final email = AuthService().currentUser?.email;
    _dashboardFuture = _apiService.getDashboardData(firebaseEmail: email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: FutureBuilder<StudentDashboardData>(
          future: _dashboardFuture,
          builder: (context, dashboardSnapshot) {
            if (dashboardSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _AppColors.primary),
              );
            }

            if (dashboardSnapshot.hasError) {
              return _ErrorView(message: dashboardSnapshot.error.toString());
            }

            final data = dashboardSnapshot.data!;

            return StreamBuilder<List<Todo>>(
              stream: _todoService.getTodos(),
              builder: (context, todoSnapshot) {
                if (todoSnapshot.hasError) {
                  return _ErrorView(message: todoSnapshot.error.toString());
                }

                final todos = todoSnapshot.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DashboardHeader(data: data),
                      const SizedBox(height: 27),
                      _DashboardHero(data: data),
                      const SizedBox(height: 31),
                      const _SectionHeader(title: 'ACADEMIC OVERVIEW'),
                      const SizedBox(height: 10),
                      _AcademicOverviewGrid(data: data),
                      const SizedBox(height: 27),
                      const _SectionHeader(title: 'TASK OVERVIEW'),
                      const SizedBox(height: 10),
                      _TaskOverviewCard(todos: todos),
                      const SizedBox(height: 31),
                      _TodoReviewHeader(onSeeAll: widget.onOpenTasks),
                      const SizedBox(height: 9),
                      _TodoReviewList(todos: todos),
                      const SizedBox(height: 72),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.data,
  });

  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: _AppColors.textDark,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatToday(),
                style: const TextStyle(
                  color: _AppColors.mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _SmallAvatar(text: _initials(data.fullName)),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.data,
  });

  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 20),
      decoration: BoxDecoration(
        color: _AppColors.primary,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.course} · ${data.yearLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  data.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  data.gwa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 39,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Overall GWA · ${data.semester}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicOverviewGrid extends StatelessWidget {
  const _AcademicOverviewGrid({
    required this.data,
  });

  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _OverviewCard(
                value: '${data.quizAverage}%',
                label: 'Quiz Average',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _OverviewCard(
                value: '${data.examAverage}%',
                label: 'Exam Average',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _OverviewCard(
                value: '${data.activityAverage}%',
                label: 'Activity Avg',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _OverviewCard(
                value: '${data.projectAverage}%',
                label: 'Project Avg',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: _AppColors.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskOverviewCard extends StatelessWidget {
  const _TaskOverviewCard({
    required this.todos,
  });

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    final pending = todos.where((todo) => !todo.isDone).length;
    final completed = todos.where((todo) => todo.isDone).length;
    final dueToday = todos.where((todo) {
      if (todo.isDone || todo.deadline == null) return false;
      return _sameDay(todo.deadline!, DateTime.now());
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: _AppColors.chipFill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TaskStatItem(
              value: pending.toString(),
              label: 'Pending',
              color: _AppColors.primary,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _TaskStatItem(
              value: completed.toString(),
              label: 'Completed',
              color: _AppColors.green,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _TaskStatItem(
              value: dueToday.toString(),
              label: 'Due Today',
              color: _AppColors.labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStatItem extends StatelessWidget {
  const _TaskStatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: _AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TodoReviewHeader extends StatelessWidget {
  const _TodoReviewHeader({
    required this.onSeeAll,
  });

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _SectionHeader(title: 'TO-DO REVIEW'),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text(
              'See all',
              style: TextStyle(
                color: _AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodoReviewList extends StatelessWidget {
  const _TodoReviewList({
    required this.todos,
  });

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    final pendingTodos = todos.where((todo) => !todo.isDone).toList();

    pendingTodos.sort((a, b) {
      if (a.deadline == null && b.deadline == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    final visibleTodos = pendingTodos.take(3).toList();

    if (visibleTodos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AppColors.chipFill,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _AppColors.border),
        ),
        child: const Text(
          'No pending tasks.',
          style: TextStyle(
            color: _AppColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: visibleTodos.map((todo) {
        return _DashboardTodoItem(todo: todo);
      }).toList(),
    );
  }
}

class _DashboardTodoItem extends StatelessWidget {
  const _DashboardTodoItem({
    required this.todo,
  });

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(todo.priority);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _AppColors.softBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todo.deadline == null
                      ? 'No due date'
                      : 'Due ${_formatShortDate(todo.deadline!)}',
                  style: const TextStyle(
                    color: _AppColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _AppColors.chipFill,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _AppColors.border),
            ),
            child: Text(
              todo.subject.trim().isEmpty ? 'N/A' : todo.subject.trim(),
              style: const TextStyle(
                color: _AppColors.labelColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
        return _AppColors.green;
      default:
        return _AppColors.mutedText;
    }
  }
}

class _ProfileScreen extends StatefulWidget {
  const _ProfileScreen();

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final _apiService = InstructorApiService();
  final _todoService = TodoService();

  late Future<StudentDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    final email = AuthService().currentUser?.email;
    _dashboardFuture = _apiService.getDashboardData(firebaseEmail: email);
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: _AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              color: _AppColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await AuthService().signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: FutureBuilder<StudentDashboardData>(
          future: _dashboardFuture,
          builder: (context, dashboardSnapshot) {
            if (dashboardSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _AppColors.primary),
              );
            }

            if (dashboardSnapshot.hasError) {
              return _ErrorView(message: dashboardSnapshot.error.toString());
            }

            final data = dashboardSnapshot.data!;

            return StreamBuilder<List<Todo>>(
              stream: _todoService.getTodos(),
              builder: (context, todoSnapshot) {
                final todos = todoSnapshot.data ?? [];
                final pendingTasks =
                    todos.where((todo) => !todo.isDone).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(17, 18, 17, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileTopHeader(data: data),
                      const SizedBox(height: 28),
                      _LargeAvatar(text: _initials(data.fullName)),
                      const SizedBox(height: 16),
                      Text(
                        data.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ProfileChip(text: data.course),
                          const SizedBox(width: 8),
                          _ProfileChip(text: data.yearLevel),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _ProfileStatsCard(
                        gwa: data.gwa.toStringAsFixed(2),
                        pendingTasks: pendingTasks.toString(),
                        subjects: data.subjectsCount.toString(),
                      ),
                      const SizedBox(height: 32),
                      const _SectionHeader(title: 'STUDENT INFORMATION'),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Student ID', value: data.studentId),
                      _InfoRow(label: 'Course', value: data.course),
                      _InfoRow(label: 'Year level', value: data.yearLevel),
                      _InfoRow(label: 'Semester', value: data.semester),
                      _InfoRow(label: 'School year', value: data.schoolYear),
                      _InfoRow(
                        label: 'Email',
                        value: data.email,
                        valueColor: _AppColors.primary,
                      ),
                      const SizedBox(height: 30),
                      const _SectionHeader(title: 'SETTINGS'),
                      const SizedBox(height: 12),
                      _SettingsButton(
                        icon: Icons.logout_rounded,
                        title: 'Log out',
                        subtitle: 'Sign out from your account',
                        color: _AppColors.danger,
                        onTap: () => _logout(context),
                      ),
                      const SizedBox(height: 70),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileTopHeader extends StatelessWidget {
  const _ProfileTopHeader({
    required this.data,
  });

  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'My Profile',
            style: TextStyle(
              color: _AppColors.textDark,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _SmallAvatar(text: _initials(data.fullName)),
      ],
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({
    required this.gwa,
    required this.pendingTasks,
    required this.subjects,
  });

  final String gwa;
  final String pendingTasks;
  final String subjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileStatItem(
              value: gwa,
              label: 'GWA',
              color: _AppColors.primary,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _ProfileStatItem(
              value: pendingTasks,
              label: 'Pending Tasks',
              color: _AppColors.green,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _ProfileStatItem(
              value: subjects,
              label: 'Subjects',
              color: _AppColors.labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _AppColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 17,
      backgroundColor: _AppColors.primaryLight,
      child: Text(
        text,
        style: const TextStyle(
          color: _AppColors.labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: _AppColors.chipFill,
          shape: BoxShape.circle,
          border: Border.all(
            color: _AppColors.primaryLight,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: _AppColors.labelColor,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _AppColors.chipFill,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _AppColors.labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _AppColors.labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            color: _AppColors.softBorder,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _AppColors.softBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: _AppColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? _AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppColors.chipFill,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _AppColors.border,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 39,
      color: _AppColors.border.withOpacity(0.55),
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
            color: _AppColors.danger,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final cleaned = name.trim();

  if (cleaned.isEmpty) return 'ST';

  final parts = cleaned
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();

  if (parts.isEmpty) return 'ST';

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _formatToday() {
  final now = DateTime.now();

  const weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

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

  return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} ${now.year}';
}

String _formatShortDate(DateTime date) {
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

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}