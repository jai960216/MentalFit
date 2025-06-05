class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup'; // 새로 추가
  static const String userTypeSelection = '/user-type';

  // Onboarding Routes
  static const String onboardingBasicInfo = '/onboarding/basic-info';
  static const String onboardingMentalCheck = '/onboarding/mental-check';
  static const String onboardingPreferences = '/onboarding/preferences';
  static const String onboardingComplete = '/onboarding/complete';

  // Main Routes
  static const String home = '/home';
  static const String aiCounseling = '/ai-counseling';

  // Counselor Routes
  static const String counselorList = '/counselors';
  static const String counselorDetail = '/counselor-detail';
  static const String booking = '/booking';

  // Chat Routes
  static const String chatList = '/chats';
  static const String chatRoom = '/chat-room';

  // Records Routes
  static const String recordsList = '/records';
  static const String recordDetail = '/record-detail';

  // Self Check Routes
  static const String selfCheckList = '/self-check';
  static const String selfCheckTest = '/self-check-test';
  static const String selfCheckResult = '/self-check-result';

  // Profile Routes
  static const String profile = '/profile';
  static const String settings = '/settings';
}
