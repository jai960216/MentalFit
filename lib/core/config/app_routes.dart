class AppRoutes {
  // === 앱 기본 ===
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // === 인증 ===
  static const String login = '/login';
  static const String signup = '/signup';
  static const String userTypeSelection = '/user-type-selection';
  static const String forgotPassword = '/forgot-password';

  // === 온보딩 ===
  static const String onboardingBasicInfo = '/onboarding/basic-info';
  static const String onboardingMentalCheck = '/onboarding/mental-check';
  static const String onboardingPreferences = '/onboarding/preferences';
  static const String onboardingComplete = '/onboarding/complete';

  // === 메인 ===
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // === AI 상담 ===
  static const String aiCounseling = '/ai-counseling';
  static const String aiCounselingDetail = '/ai-counseling/detail';

  // === 상담사 ===
  static const String counselorList = '/counselor/list';
  static const String counselorDetail = '/counselor/detail';
  static const String counselorSearch = '/counselor/search';

  // === 예약/예약 관리 === (수정됨)
  static const String bookingCalendar =
      '/booking/calendar'; // 변경: booking -> bookingCalendar
  static const String bookingList = '/booking/list';
  static const String bookingDetail = '/booking/detail';
  static const String bookingConfirm = '/booking/confirm';

  // === 채팅 ===
  static const String chatList = '/chat/list';
  static const String chatRoom = '/chat/room';
  static const String aiChatRoom = '/chat/ai';

  // === 상담 기록 ===
  static const String recordsList = '/records/list';
  static const String recordDetail = '/records/detail';
  static const String createRecord = '/records/create';

  // === 자가진단 ===
  static const String selfCheckList = '/self-check/list';
  static const String selfCheckTest = '/self-check/test';
  static const String selfCheckResult = '/self-check/result';
  static const String selfCheckHistory = '/self-check/history';

  // === 프로필/설정 ===
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String notifications = '/settings/notifications';
  static const String privacy = '/settings/privacy';
  static const String terms = '/settings/terms';
  static const String help = '/settings/help';

  // === 기타 ===
  static const String webview = '/webview';
  static const String imageViewer = '/image-viewer';
  static const String videoPlayer = '/video-player';

  // === URL 생성 헬퍼 메서드들 ===

  // 상담사 상세 페이지 URL 생성
  static String getCounselorDetailRoute(String counselorId) =>
      '$counselorDetail/$counselorId';

  // 예약 캘린더 URL 생성 (수정됨)
  static String getBookingCalendarRoute(String counselorId) =>
      '$bookingCalendar/$counselorId';

  // 예약 확정 URL 생성 (추가됨)
  static String getBookingConfirmRoute(String counselorId) =>
      '$bookingConfirm/$counselorId';

  // 채팅방 URL 생성
  static String getChatRoomRoute(String roomId) => '$chatRoom/$roomId';

  // 예약 상세 페이지 URL 생성
  static String getBookingDetailRoute(String bookingId) =>
      '$bookingDetail/$bookingId';

  // 기록 상세 페이지 URL 생성
  static String getRecordDetailRoute(String recordId) =>
      '$recordDetail/$recordId';

  // 자가진단 테스트 URL 생성
  static String getSelfCheckTestRoute(String testId) =>
      '$selfCheckTest/$testId';

  // 자가진단 결과 URL 생성
  static String getSelfCheckResultRoute(String resultId) =>
      '$selfCheckResult/$resultId';

  // 웹뷰 URL 생성
  static String getWebviewRoute(String url, {String? title}) {
    final uri = Uri.parse(webview);
    return uri
        .replace(
          queryParameters: {'url': url, if (title != null) 'title': title},
        )
        .toString();
  }

  // 이미지 뷰어 URL 생성
  static String getImageViewerRoute(
    List<String> imageUrls, {
    int initialIndex = 0,
  }) {
    final uri = Uri.parse(imageViewer);
    return uri
        .replace(
          queryParameters: {
            'urls': imageUrls.join(','),
            'index': initialIndex.toString(),
          },
        )
        .toString();
  }

  // === 네비게이션 체크 메서드들 ===

  // 인증이 필요한 라우트인지 확인
  static bool isAuthRequired(String route) {
    const publicRoutes = [
      splash,
      login,
      signup,
      userTypeSelection,
      forgotPassword,
      onboarding,
      onboardingBasicInfo,
      onboardingMentalCheck,
      onboardingPreferences,
      onboardingComplete,
    ];

    return !publicRoutes.any((publicRoute) => route.startsWith(publicRoute));
  }

  // 온보딩이 완료되어야 하는 라우트인지 확인
  static bool isOnboardingRequired(String route) {
    const onboardingRoutes = [
      onboarding,
      onboardingBasicInfo,
      onboardingMentalCheck,
      onboardingPreferences,
      onboardingComplete,
      login,
      signup,
      userTypeSelection,
      forgotPassword,
      splash,
    ];

    return !onboardingRoutes.any(
      (onboardingRoute) => route.startsWith(onboardingRoute),
    );
  }

  // 메인 탭 라우트인지 확인
  static bool isMainTabRoute(String route) {
    const mainTabRoutes = [home, chatList, recordsList, profile];

    return mainTabRoutes.any((tabRoute) => route.startsWith(tabRoute));
  }

  // 풀스크린 라우트인지 확인 (바텀 네비게이션 숨김)
  static bool isFullScreenRoute(String route) {
    const fullScreenRoutes = [
      chatRoom,
      aiChatRoom,
      videoPlayer,
      selfCheckTest,
      webview,
      imageViewer,
    ];

    return fullScreenRoutes.any(
      (fullScreenRoute) => route.startsWith(fullScreenRoute),
    );
  }

  // 라우트 이름 추출 (매개변수 제외)
  static String getRouteName(String route) {
    final uri = Uri.parse(route);
    final pathSegments = uri.pathSegments;

    if (pathSegments.isEmpty) return splash;

    // 동적 매개변수가 있는 라우트들 처리
    if (pathSegments.length >= 2) {
      final basePath = '/${pathSegments[0]}/${pathSegments[1]}';

      // 알려진 동적 라우트들 (수정됨)
      const dynamicRoutes = [
        counselorDetail,
        chatRoom,
        bookingDetail,
        bookingCalendar, // 추가
        bookingConfirm, // 추가
        recordDetail,
        selfCheckTest,
        selfCheckResult,
      ];

      if (dynamicRoutes.contains(basePath)) {
        return basePath;
      }
    }

    return uri.path;
  }

  // 라우트별 타이틀 가져오기 (수정됨)
  static String getRouteTitle(String route) {
    final routeName = getRouteName(route);

    const routeTitles = {
      home: '홈',
      login: '로그인',
      signup: '회원가입',
      userTypeSelection: '사용자 유형 선택',
      forgotPassword: '비밀번호 찾기',
      aiCounseling: 'AI 상담',
      counselorList: '상담사 찾기',
      counselorDetail: '상담사 정보',
      bookingList: '예약 관리',
      bookingCalendar: '예약하기', // 수정됨
      bookingConfirm: '예약 확정', // 추가됨
      bookingDetail: '예약 상세', // 추가됨
      chatList: '채팅',
      chatRoom: '채팅',
      aiChatRoom: 'AI 채팅',
      recordsList: '상담 기록',
      recordDetail: '기록 상세',
      selfCheckList: '자가진단',
      selfCheckTest: '자가진단 테스트',
      selfCheckResult: '진단 결과',
      profile: '마이페이지',
      settings: '설정',
      editProfile: '프로필 수정',
      notifications: '알림 설정',
      privacy: '개인정보 처리방침',
      terms: '이용약관',
      help: '도움말',
    };

    return routeTitles[routeName] ?? '멘탈핏';
  }

  // 라우트별 아이콘 가져오기 (바텀 네비게이션용)
  static String getRouteIcon(String route) {
    final routeName = getRouteName(route);

    const routeIcons = {
      home: 'home',
      chatList: 'chat',
      recordsList: 'assignment',
      profile: 'person',
    };

    return routeIcons[routeName] ?? 'help_outline';
  }
}
