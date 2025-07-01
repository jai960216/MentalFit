#!/bin/bash

echo "🔧 Google 로그인 리다이렉트 자동 수정 중..."

# REVERSED_CLIENT_ID 추출
REVERSED_CLIENT_ID=$(grep -A 1 "REVERSED_CLIENT_ID" ios/Runner/GoogleService-Info.plist | grep -o "com\.googleusercontent\.apps\.[^<]*")

if [ -z "$REVERSED_CLIENT_ID" ]; then
    echo "❌ REVERSED_CLIENT_ID를 찾을 수 없습니다."
    exit 1
fi

echo "✅ REVERSED_CLIENT_ID: $REVERSED_CLIENT_ID"

INFO_PLIST="ios/Runner/Info.plist"

# 기존 CFBundleURLTypes 삭제
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$INFO_PLIST" 2>/dev/null

# 새로운 CFBundleURLTypes 추가 (2개 URL Scheme)
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$INFO_PLIST"

# 첫 번째: Google Sign-In
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string google-signin" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLRole string Editor" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string $REVERSED_CLIENT_ID" "$INFO_PLIST"

# 두 번째: Bundle ID
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1 dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLName string bundle-id" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLRole string Editor" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:1:CFBundleURLSchemes:0 string com.mentalfit.sports" "$INFO_PLIST"

# LSApplicationQueriesSchemes 업데이트 (iOS 시뮬레이터 지원 추가)
/usr/libexec/PlistBuddy -c "Delete :LSApplicationQueriesSchemes" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:0 string googlechrome" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:1 string googlechromes" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:2 string googlegmail" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:3 string googleplus" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:4 string googledrive" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:5 string https" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes:6 string http" "$INFO_PLIST"

# iOS 시뮬레이터를 위한 추가 설정
/usr/libexec/PlistBuddy -c "Add :CFBundleAllowMixedLocalizations bool true" "$INFO_PLIST" 2>/dev/null

# NSAppTransportSecurity 설정 (iOS 시뮬레이터에서 HTTPS 문제 해결)
/usr/libexec/PlistBuddy -c "Delete :NSAppTransportSecurity" "$INFO_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSAllowsArbitraryLoads bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$INFO_PLIST"

# Google APIs 도메인 예외
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleapis.com dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleapis.com:NSExceptionAllowsInsecureHTTPLoads bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleapis.com:NSExceptionMinimumTLSVersion string TLSv1.0" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleapis.com:NSExceptionRequiresForwardSecrecy bool false" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleapis.com:NSIncludesSubdomains bool true" "$INFO_PLIST"

# Google User Content 도메인 예외
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleusercontent.com dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleusercontent.com:NSExceptionAllowsInsecureHTTPLoads bool true" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleusercontent.com:NSExceptionMinimumTLSVersion string TLSv1.0" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleusercontent.com:NSExceptionRequiresForwardSecrecy bool false" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :NSAppTransportSecurity:NSExceptionDomains:googleusercontent.com:NSIncludesSubdomains bool true" "$INFO_PLIST"

echo "✅ Info.plist 수정 완료!"

# 검증
echo ""
echo "📋 수정된 설정 확인:"
echo "URL Schemes:"
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:0:CFBundleURLSchemes:0" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Print :CFBundleURLTypes:1:CFBundleURLSchemes:0" "$INFO_PLIST"

echo ""
echo "🔧 iOS 시뮬레이터 전용 설정:"
echo "1. 시뮬레이터에서 Safari 앱을 열고 Google 계정에 로그인되어 있는지 확인"
echo "2. 시뮬레이터 설정 > Safari > Advanced > Web Inspector 활성화"
echo "3. 시뮬레이터 설정 > Safari > Advanced > JavaScript 활성화"

echo ""
echo "🚀 이제 다음 명령어로 테스트:"
echo "flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run"