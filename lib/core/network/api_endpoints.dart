class ApiEndpoints {
  // 기본 URL (환경별로 변경 가능)
  static const String _baseUrl = 'https://api.mentalfit.app';

  // 개발용 URL (실제 서버가 없으므로 임시)
  static const String _devUrl = 'https://dev-api.mentalfit.app';

  // 현재 환경에 맞는 기본 URL
  static const String baseUrl = _devUrl; // 개발 시에는 dev URL 사용

  // === 인증 관련 ===
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String socialLogin = '/auth/social';

  // === 사용자 관련 ===
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String deleteAccount = '/user/delete';

  // === 온보딩 관련 ===
  static const String saveOnboarding = '/onboarding/save';
  static const String getOnboarding = '/onboarding/get';
  static const String completeOnboarding = '/onboarding/complete';

  // === 채팅 관련 ===
  static const String chatRooms = '/chat/rooms';
  static const String createChatRoom = '/chat/rooms/create';
  static const String getChatRoom = '/chat/rooms'; // + /{roomId}
  static const String sendMessage = '/chat/messages/send';
  static const String getMessages = '/chat/messages'; // + /{roomId}
  static const String markAsRead = '/chat/messages/read';

  // === AI 상담 관련 ===
  static const String aiChat = '/ai/chat';
  static const String aiChatHistory = '/ai/chat/history';
  static const String aiTopics = '/ai/topics';

  // === 상담사 관련 ===
  static const String counselors = '/counselors';
  static const String counselorDetail = '/counselors'; // + /{counselorId}
  static const String bookAppointment = '/counselors/book';
  static const String appointments = '/appointments';
  static const String cancelAppointment = '/appointments/cancel';

  // === 자가진단 관련 ===
  static const String selfCheckTests = '/self-check/tests';
  static const String submitSelfCheck = '/self-check/submit';
  static const String selfCheckResults = '/self-check/results';
  static const String selfCheckHistory = '/self-check/history';

  // === 기록 관리 ===
  static const String records = '/records';
  static const String recordDetail = '/records'; // + /{recordId}
  static const String saveRecord = '/records/save';
  static const String deleteRecord = '/records/delete';

  // === 설정 관련 ===
  static const String userSettings = '/settings';
  static const String updateSettings = '/settings/update';
  static const String notificationSettings = '/settings/notifications';

  // === 공통 기능 ===
  static const String uploadFile = '/files/upload';
  static const String downloadFile = '/files/download';
  static const String healthCheck = '/health';

  // URL 생성 헬퍼 메서드들
  static String getChatRoomUrl(String roomId) => '$getChatRoom/$roomId';
  static String getMessagesUrl(String roomId) => '$getMessages/$roomId';
  static String getCounselorDetailUrl(String counselorId) =>
      '$counselorDetail/$counselorId';
  static String getRecordDetailUrl(String recordId) =>
      '$recordDetail/$recordId';

  // 전체 URL 생성
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';

  // WebSocket 엔드포인트 (실시간 채팅용)
  static const String wsBaseUrl = 'wss://ws.mentalfit.app';
  static const String wsChatRoom = '/ws/chat';
  static String getWsChatRoomUrl(String roomId) =>
      '$wsBaseUrl$wsChatRoom/$roomId';
}

// API 버전 관리
class ApiVersions {
  static const String v1 = '/v1';
  static const String v2 = '/v2';
  static const String current = v1;
}

// HTTP 헤더 상수
class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String accept = 'Accept';
  static const String userAgent = 'User-Agent';
  static const String xApiKey = 'X-API-Key';

  // 값들
  static const String applicationJson = 'application/json';
  static const String multipartFormData = 'multipart/form-data';
  static const String bearer = 'Bearer';
}

// HTTP 상태 코드
class HttpStatusCodes {
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;

  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int methodNotAllowed = 405;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;

  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
  static const int gatewayTimeout = 504;
}
