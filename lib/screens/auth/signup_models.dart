import '../../shared/models/user_model.dart';

// === 회원가입 정보 모델 ===
class SignupInfo {
  final String email;
  final String password;
  final String name;
  final UserType userType;

  const SignupInfo({
    required this.email,
    required this.password,
    required this.name,
    required this.userType,
  });

  // Map으로부터 생성
  factory SignupInfo.fromMap(Map<String, dynamic> map) {
    return SignupInfo(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      name: map['name'] ?? '',
      userType: UserType.values.firstWhere(
        (type) => type.value == map['userType'],
        orElse: () => UserType.athlete,
      ),
    );
  }

  // Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'userType': userType.value,
    };
  }

  @override
  String toString() {
    return 'SignupInfo(email: $email, name: $name, userType: $userType)';
  }
}

// === 소셜 로그인 유형 ===
enum SocialLoginType {
  google('google', 'Google');

  const SocialLoginType(this.value, this.displayName);

  final String value;
  final String displayName;

  @override
  String toString() => displayName;
}

// === 상수들 ===
class SignupConstants {
  // 이용약관 내용
  static const String termsContent = '''제1조 (목적)
이 약관은 MentalFit(이하 "회사")가 제공하는 스포츠 심리 상담 서비스의 이용조건 및 절차에 관한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 회사가 제공하는 모든 스포츠 심리 상담 관련 서비스를 의미합니다.
② "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.
③ "회원"이란 회사에 개인정보를 제공하여 회원등록을 한 자로서, 회사의 정보를 지속적으로 제공받으며 회사가 제공하는 서비스를 계속적으로 이용할 수 있는 자를 말합니다.

제3조 (약관의 게시와 개정)
① 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.
② 회사는 관련 법령을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.

제4조 (서비스의 제공)
① 회사는 다음과 같은 서비스를 제공합니다:
- AI 기반 심리 상담 서비스
- 전문 상담사와의 1:1 상담 서비스
- 자가진단 및 심리 검사 서비스
- 상담 기록 관리 서비스

제5조 (이용자의 의무)
① 이용자는 다음 행위를 하여서는 안 됩니다:
- 신청 또는 변경 시 허위내용의 등록
- 타인의 정보 도용
- 회사가 게시한 정보의 변경
- 회사 및 제3자의 저작권 등 지적재산권에 대한 침해

이용약관에 대한 자세한 내용은 서비스 내에서 확인하실 수 있습니다.''';

  // 개인정보처리방침 내용
  static const String privacyContent = '''1. 개인정보의 처리목적
MentalFit(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다:
- 회원 가입 및 관리
- 서비스 제공 및 계약의 이행
- 고객 상담 및 민원 처리
- 서비스 개선 및 신규 서비스 개발

2. 개인정보의 처리 및 보유기간
① 회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
② 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
- 회원 가입 및 관리: 회원 탈퇴 시까지
- 상담 서비스 제공: 서비스 종료 후 3년

3. 개인정보의 제3자 제공
회사는 원칙적으로 정보주체의 개인정보를 수집·이용 목적으로 명시한 범위 내에서 처리하며, 정보주체의 사전 동의 없이는 본래의 목적 범위를 초과하여 처리하거나 제3자에게 제공하지 않습니다.

4. 개인정보처리의 위탁
회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:
- 위탁업체: AWS, Firebase 등
- 위탁업무: 서버 운영 및 데이터 저장

5. 정보주체의 권리·의무 및 행사방법
정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:
- 개인정보 처리정지 요구권
- 개인정보 열람요구권
- 개인정보 정정·삭제요구권
- 개인정보 처리정지 요구권

자세한 개인정보처리방침은 서비스 내에서 확인하실 수 있습니다.''';

  // 유효성 검사 메시지
  static const Map<String, String> validationMessages = {
    'nameEmpty': '이름을 입력해주세요',
    'nameShort': '이름은 2자 이상이어야 합니다',
    'emailEmpty': '이메일을 입력해주세요',
    'emailInvalid': '올바른 이메일 형식을 입력해주세요',
    'passwordEmpty': '비밀번호를 입력해주세요',
    'passwordShort': '비밀번호는 6자 이상이어야 합니다',
    'passwordWeak': '비밀번호는 영문과 숫자를 포함해야 합니다',
    'passwordConfirmEmpty': '비밀번호 확인을 입력해주세요',
    'passwordMismatch': '비밀번호가 일치하지 않습니다',
    'agreementRequired': '이용약관과 개인정보처리방침에 동의해주세요',
  };

  // 성공 메시지
  static const Map<String, String> successMessages = {
    'signupComplete': '회원가입이 완료되었습니다!',
    'googleSignupComplete': 'Google 회원가입이 완료되었습니다!',
  };

  // 에러 메시지
  static const Map<String, String> errorMessages = {
    'signupFailed': '회원가입에 실패했습니다',
    'socialSignupFailed': '소셜 회원가입에 실패했습니다',
    'networkError': '네트워크 연결을 확인해주세요',
    'serverError': '서버 오류가 발생했습니다',
  };
}
