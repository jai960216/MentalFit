# iOS 시뮬레이터 Google 로그인 문제 해결 가이드

## 🔍 문제 분석
iOS 시뮬레이터에서 "응답을 분석할 수 없다"는 오류는 주로 다음 원인들로 발생합니다:

1. **URL Scheme 처리 문제**: 앱이 Google 인증 후 리다이렉트를 제대로 처리하지 못함
2. **HTTPS/네트워크 보안 문제**: iOS 시뮬레이터에서 Google API 접근 제한
3. **Safari 설정 문제**: 시뮬레이터의 Safari가 Google 인증을 제대로 처리하지 못함

## ✅ 해결 방법

### 1. 시뮬레이터 Safari 설정
```bash
# 시뮬레이터에서 다음 설정을 확인하세요:
# 1. Safari 앱 열기
# 2. Settings > Safari > Advanced
# 3. Web Inspector: ON
# 4. JavaScript: ON
# 5. Google 계정에 로그인되어 있는지 확인
```

### 2. 프로젝트 클린 및 재빌드
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### 3. 추가 디버깅 설정

#### Info.plist에 추가된 설정들:
- ✅ `CFBundleURLTypes`: Google Sign-In URL Scheme
- ✅ `LSApplicationQueriesSchemes`: HTTPS/HTTP 지원
- ✅ `NSAppTransportSecurity`: Google 도메인 예외 설정
- ✅ `CFBundleAllowMixedLocalizations`: 다국어 지원

#### AppDelegate.swift에 추가된 설정들:
- ✅ URL 처리 메서드 오버라이드
- ✅ Google Sign-In URL Scheme 처리
- ✅ Bundle ID URL Scheme 처리

### 4. Google Sign-In 설정 개선
- ✅ `serverClientId` 추가로 웹 기반 인증 강제
- ✅ iOS 시뮬레이터 호환성 향상

## 🚨 추가 문제 해결

### 만약 여전히 문제가 발생한다면:

1. **Firebase Console 확인**:
   - iOS 앱 설정에서 Bundle ID가 `com.mentalfit.sports`로 올바르게 설정되어 있는지 확인
   - GoogleService-Info.plist의 REVERSED_CLIENT_ID가 Info.plist의 URL Scheme과 일치하는지 확인

2. **시뮬레이터 재설정**:
   ```bash
   # 시뮬레이터 완전 초기화
   xcrun simctl erase all
   ```

3. **Xcode에서 직접 실행**:
   ```bash
   cd ios
   open Runner.xcworkspace
   # Xcode에서 시뮬레이터로 직접 실행
   ```

4. **Google 계정 확인**:
   - 시뮬레이터의 Safari에서 Google 계정에 로그인되어 있는지 확인
   - 테스트용 Google 계정이 Firebase 프로젝트에 추가되어 있는지 확인

## 📱 테스트 방법

1. 앱 실행 후 Google 로그인 버튼 클릭
2. Safari가 열리면서 Google 로그인 페이지 표시
3. Google 계정 선택 및 로그인
4. 앱으로 자동 리다이렉트되어 로그인 완료

## 🔧 디버깅 팁

- Xcode 콘솔에서 로그 확인
- Flutter 디버그 콘솔에서 오류 메시지 확인
- Safari 개발자 도구에서 네트워크 요청 확인

## 📞 추가 지원

문제가 지속되면 다음 정보를 확인해주세요:
- Xcode 버전
- iOS 시뮬레이터 버전
- Flutter 버전
- 구체적인 오류 메시지 