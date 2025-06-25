# MentalFit - 스포츠 심리 상담 전문 앱

MentalFit은 운동선수와 스포츠인들을 위한 전문적인 심리 상담 서비스를 제공하는 모바일 애플리케이션입니다.

## 주요 기능

### 🤖 AI 기반 상담
- 24시간 언제든지 이용 가능한 AI 챗봇 상담
- 개인 맞춤형 심리 상담 및 조언 제공
- 스포츠 상황별 특화된 상담 서비스

### 👨‍⚕️ 전문 상담사 매칭
- 자격을 갖춘 전문 상담사와의 실시간 상담
- 화상, 음성, 채팅을 통한 다양한 상담 방식
- 스포츠 심리 전문가 매칭

### 📊 자가진단 및 심리 검사
- 스트레스, 불안, 우울 등의 자가진단 도구
- 개인 맞춤형 심리 검사 및 결과 분석
- 정기적인 심리 상태 모니터링

### 📝 상담 기록 관리
- 상담 내역 및 진행 상황 기록
- 개인 성장 및 변화 추적 관리
- 데이터 기반 성과 분석

## 기술 스택

- **Frontend**: Flutter 3.7.2
- **Backend**: Firebase (Firestore, Auth, Storage)
- **AI**: OpenAI GPT API
- **State Management**: Riverpod
- **Navigation**: Go Router
- **UI**: Material Design 3

## 개발 환경 설정

### 필수 요구사항
- Flutter SDK 3.7.2 이상
- Dart SDK 3.0.0 이상
- Android Studio / VS Code
- iOS 개발 시 Xcode 14.0 이상

### 설치 및 실행

1. 저장소 클론
```bash
git clone [repository-url]
cd MentalFit
```

2. 의존성 설치
```bash
flutter pub get
```

3. 환경 변수 설정
```bash
cp .env.example .env
# .env 파일에 필요한 API 키들을 설정
```

4. 앱 실행
```bash
flutter run
```

## 빌드 및 배포

### Android 빌드
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS 빌드
```bash
flutter build ios --release
flutter build ipa
```

## 개인정보 보호

MentalFit은 사용자의 개인정보 보호를 최우선으로 합니다.

- **개인정보처리방침**: 앱 내 설정에서 확인 가능
- **데이터 암호화**: 모든 민감한 데이터는 암호화되어 저장
- **권한 최소화**: 필요한 최소한의 권한만 요청

## 지원 및 문의

- **고객센터**: 1588-1234
- **이메일**: support@mentalfit.co.kr
- **운영시간**: 평일 09:00 - 18:00

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

© 2024 MentalFit. All rights reserved.
