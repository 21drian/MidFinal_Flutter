class InstructorApiService {
  // Keep this true while your instructor API is not yet available.
  static const bool useMockData = true;

  Future<StudentDashboardData> getDashboardData({String? firebaseEmail}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (useMockData) {
      return StudentDashboardData(
        fullName: 'Adrian Paul Macalolot',
        studentId: '2024-00217',
        course: 'BS Information Technology',
        yearLevel: '3rd Year',
        semester: '2nd Semester',
        schoolYear: '2025 - 2026',
        email: firebaseEmail ?? 'ap.macalolot@school.edu',
        gwa: 1.50,
        quizAverage: 86,
        examAverage: 91,
        activityAverage: 88,
        projectAverage: 95,
        subjectsCount: 6,
        grades: const [
          InstructorGrade(
            subjectCode: 'ITC 130',
            subjectName: 'Application Development',
            grade: 1.50,
            quizAverage: 86,
            examAverage: 91,
            activityAverage: 88,
            projectAverage: 95,
          ),
          InstructorGrade(
            subjectCode: 'ERD 101',
            subjectName: 'Database Systems',
            grade: 1.75,
            quizAverage: 84,
            examAverage: 89,
            activityAverage: 87,
            projectAverage: 93,
          ),
          InstructorGrade(
            subjectCode: 'ITC 150',
            subjectName: 'Capstone Preparation',
            grade: 1.25,
            quizAverage: 90,
            examAverage: 94,
            activityAverage: 91,
            projectAverage: 97,
          ),
        ],
      );
    }

    // Later, replace this part with your instructor API request.
    throw UnimplementedError('Instructor API is not connected yet.');
  }

  Future<List<InstructorGrade>> getGrades({String? firebaseEmail}) async {
    final dashboard = await getDashboardData(firebaseEmail: firebaseEmail);
    return dashboard.grades;
  }
}

class StudentDashboardData {
  const StudentDashboardData({
    required this.fullName,
    required this.studentId,
    required this.course,
    required this.yearLevel,
    required this.semester,
    required this.schoolYear,
    required this.email,
    required this.gwa,
    required this.quizAverage,
    required this.examAverage,
    required this.activityAverage,
    required this.projectAverage,
    required this.subjectsCount,
    required this.grades,
  });

  final String fullName;
  final String studentId;
  final String course;
  final String yearLevel;
  final String semester;
  final String schoolYear;
  final String email;

  final double gwa;
  final int quizAverage;
  final int examAverage;
  final int activityAverage;
  final int projectAverage;
  final int subjectsCount;

  final List<InstructorGrade> grades;
}

class InstructorGrade {
  const InstructorGrade({
    required this.subjectCode,
    required this.subjectName,
    required this.grade,
    required this.quizAverage,
    required this.examAverage,
    required this.activityAverage,
    required this.projectAverage,
  });

  final String subjectCode;
  final String subjectName;
  final double grade;
  final int quizAverage;
  final int examAverage;
  final int activityAverage;
  final int projectAverage;
}
