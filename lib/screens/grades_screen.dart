import 'package:flutter/material.dart';
import '../services/services.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _apiService = InstructorApiService();

  late Future<StudentDashboardData> _dashboardFuture;

  static const _primary = Color(0xFFE6532E);
  static const _primaryLight = Color(0xFFF6C06F);
  static const _textDark = Color(0xFF2D2D2D);
  static const _mutedText = Color(0xFF8E8E8E);
  static const _labelColor = Color(0xFF8B4D07);
  static const _border = Color(0xFFF2BE73);
  static const _softBorder = Color(0xFFF0E4D4);
  static const _chipFill = Color(0xFFFFF6E8);
  static const _danger = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    final email = AuthService().currentUser?.email;
    _dashboardFuture = _apiService.getDashboardData(firebaseEmail: email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<StudentDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load grades: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final grades = data.grades;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(17, 18, 17, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'My Grades',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Read-only data from instructor API',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 23),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: _primary,
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
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 17),
                              Text(
                                data.gwa.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              Text(
                                'Overall GWA · ${data.semester}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  ),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'SUBJECT GRADES'),
                  const SizedBox(height: 10),
                  if (grades.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _chipFill,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _border),
                      ),
                      child: const Text(
                        'No grades available.',
                        style: TextStyle(
                          color: _mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: grades.map((grade) {
                        return _GradeCard(grade: grade);
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
  });

  final InstructorGrade grade;

  static const _primary = Color(0xFFE6532E);
  static const _textDark = Color(0xFF2D2D2D);
  static const _mutedText = Color(0xFF8E8E8E);
  static const _labelColor = Color(0xFF8B4D07);
  static const _border = Color(0xFFF2BE73);
  static const _chipFill = Color(0xFFFFF6E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _chipFill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  grade.subjectCode,
                  style: const TextStyle(
                    color: _labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                grade.grade.toStringAsFixed(2),
                style: const TextStyle(
                  color: _primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            grade.subjectName,
            style: const TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniMetric(label: 'Quiz', value: '${grade.quizAverage}%'),
              _MiniMetric(label: 'Exam', value: '${grade.examAverage}%'),
              _MiniMetric(label: 'Activity', value: '${grade.activityAverage}%'),
              _MiniMetric(label: 'Project', value: '${grade.projectAverage}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static const _primary = Color(0xFFE6532E);
  static const _mutedText = Color(0xFF8E8E8E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  static const _labelColor = Color(0xFF8B4D07);
  static const _softBorder = Color(0xFFF0E4D4);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
            color: _softBorder,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}