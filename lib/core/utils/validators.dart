class Validators {
  // 이메일 유효성 검사
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }

    // 기본 이메일 형식 검사
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }

    return null;
  }

  // 비밀번호 유효성 검사
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }

    if (value.length > 50) {
      return '비밀번호는 50자 이하여야 합니다';
    }

    // 영문과 숫자를 포함해야 함
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다';
    }

    return null;
  }

  // 비밀번호 확인 유효성 검사
  static String? validatePasswordConfirm(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }

  // 이름 유효성 검사
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }

    if (value.length < 2) {
      return '이름은 2자 이상이어야 합니다';
    }

    if (value.length > 20) {
      return '이름은 20자 이하여야 합니다';
    }

    // 한글, 영문, 공백만 허용
    if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(value)) {
      return '이름은 한글 또는 영문만 입력 가능합니다';
    }

    return null;
  }

  // 전화번호 유효성 검사
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '전화번호를 입력해주세요';
    }

    // 숫자와 하이픈만 허용
    final phoneRegex = RegExp(r'^[0-9-]+$');
    if (!phoneRegex.hasMatch(value)) {
      return '올바른 전화번호 형식을 입력해주세요';
    }

    // 숫자만 추출해서 길이 확인
    final numbersOnly = value.replaceAll('-', '');
    if (numbersOnly.length < 10 || numbersOnly.length > 11) {
      return '올바른 전화번호를 입력해주세요';
    }

    return null;
  }

  // 생년월일 유효성 검사
  static String? validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return '생년월일을 입력해주세요';
    }

    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();

      // 미래 날짜 체크
      if (date.isAfter(now)) {
        return '생년월일은 미래 날짜일 수 없습니다';
      }

      // 너무 과거 날짜 체크 (120년 전)
      final minDate = DateTime(now.year - 120);
      if (date.isBefore(minDate)) {
        return '올바른 생년월일을 입력해주세요';
      }

      // 너무 최근 날짜 체크 (5세 미만)
      final maxDate = DateTime(now.year - 5);
      if (date.isAfter(maxDate)) {
        return '5세 이상만 가입 가능합니다';
      }
    } catch (e) {
      return '올바른 날짜 형식을 입력해주세요';
    }

    return null;
  }

  // 필수 입력 필드 유효성 검사
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }

  // 최소 길이 유효성 검사
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }

    if (value.length < minLength) {
      return '$fieldName은(는) $minLength자 이상이어야 합니다';
    }

    return null;
  }

  // 최대 길이 유효성 검사
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null) return null;

    if (value.length > maxLength) {
      return '$fieldName은(는) $maxLength자 이하여야 합니다';
    }

    return null;
  }

  // 숫자만 허용 유효성 검사
  static String? validateNumericOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName은(는) 숫자만 입력 가능합니다';
    }

    return null;
  }

  // 한글만 허용 유효성 검사
  static String? validateKoreanOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }

    if (!RegExp(r'^[가-힣\s]+$').hasMatch(value)) {
      return '$fieldName은(는) 한글만 입력 가능합니다';
    }

    return null;
  }

  // 영문만 허용 유효성 검사
  static String? validateEnglishOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName은(는) 영문만 입력 가능합니다';
    }

    return null;
  }

  // URL 유효성 검사
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL은 선택사항일 수 있음
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return '올바른 URL 형식을 입력해주세요';
      }
    } catch (e) {
      return '올바른 URL 형식을 입력해주세요';
    }

    return null;
  }

  // 사용자 정의 정규식 유효성 검사
  static String? validateRegex(
    String? value,
    RegExp regex,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (!regex.hasMatch(value)) {
      return errorMessage;
    }

    return null;
  }

  // 여러 검증 규칙을 조합하는 유틸리티
  static String? validateMultiple(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result; // 첫 번째 에러 반환
      }
    }
    return null;
  }

  // 조건부 필수 입력 검사
  static String? validateConditionalRequired(
    String? value,
    bool isRequired,
    String fieldName,
  ) {
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }
}
