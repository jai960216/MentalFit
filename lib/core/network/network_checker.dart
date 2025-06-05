import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  static NetworkChecker? _instance;
  final Connectivity _connectivity = Connectivity();

  StreamController<bool>? _connectionStatusController;
  Stream<bool>? _connectionStatusStream;

  bool _isConnected = true;
  bool _isInitialized = false;

  // 싱글톤 패턴
  NetworkChecker._();

  static NetworkChecker get instance {
    _instance ??= NetworkChecker._();
    return _instance!;
  }

  // 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    _connectionStatusController = StreamController<bool>.broadcast();
    _connectionStatusStream = _connectionStatusController!.stream;

    // 초기 연결 상태 확인
    _isConnected = await isConnected();

    // 연결 상태 변화 모니터링 (최신 API 사용)
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(
        results.isNotEmpty ? results.first : ConnectivityResult.none,
      );
    });

    _isInitialized = true;
  }

  // 현재 연결 상태 확인
  Future<bool> isConnected() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final connectivityResult =
          connectivityResults.isNotEmpty
              ? connectivityResults.first
              : ConnectivityResult.none;

      // 연결 타입이 none이면 연결 안됨
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // 실제 인터넷 연결 확인 (Google DNS로 ping)
      return await _pingTest();
    } catch (e) {
      return false;
    }
  }

  // 실제 인터넷 연결 테스트
  Future<bool> _pingTest() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // 연결 상태 업데이트
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final wasConnected = _isConnected;
    _isConnected = await isConnected();

    // 상태가 변경된 경우에만 알림
    if (wasConnected != _isConnected) {
      _connectionStatusController?.add(_isConnected);
    }
  }

  // 연결 상태 스트림
  Stream<bool>? get connectionStatusStream => _connectionStatusStream;

  // 현재 연결 상태 (캐시된 값)
  bool get isCurrentlyConnected => _isConnected;

  // 연결 타입 확인
  Future<NetworkType> getNetworkType() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final connectivityResult =
        connectivityResults.isNotEmpty
            ? connectivityResults.first
            : ConnectivityResult.none;

    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.none:
        return NetworkType.none;
      default:
        return NetworkType.unknown;
    }
  }

  // 연결 품질 테스트
  Future<NetworkQuality> testNetworkQuality() async {
    if (!await isConnected()) {
      return NetworkQuality.none;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // 작은 데이터로 속도 테스트
      final result = await InternetAddress.lookup('google.com');
      stopwatch.stop();

      if (result.isEmpty) {
        return NetworkQuality.none;
      }

      final responseTime = stopwatch.elapsedMilliseconds;

      if (responseTime < 100) {
        return NetworkQuality.excellent;
      } else if (responseTime < 300) {
        return NetworkQuality.good;
      } else if (responseTime < 1000) {
        return NetworkQuality.fair;
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      return NetworkQuality.none;
    }
  }

  // 리소스 정리
  void dispose() {
    _connectionStatusController?.close();
    _connectionStatusController = null;
    _connectionStatusStream = null;
    _isInitialized = false;
  }
}

// 네트워크 타입
enum NetworkType { wifi, mobile, ethernet, none, unknown }

// 네트워크 품질
enum NetworkQuality {
  excellent, // < 100ms
  good, // 100-300ms
  fair, // 300-1000ms
  poor, // > 1000ms
  none, // 연결 없음
}

// 네트워크 상태 정보
class NetworkStatus {
  final bool isConnected;
  final NetworkType type;
  final NetworkQuality quality;
  final DateTime timestamp;

  const NetworkStatus({
    required this.isConnected,
    required this.type,
    required this.quality,
    required this.timestamp,
  });

  factory NetworkStatus.disconnected() {
    return NetworkStatus(
      isConnected: false,
      type: NetworkType.none,
      quality: NetworkQuality.none,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'NetworkStatus(connected: $isConnected, type: $type, quality: $quality)';
  }
}

// 네트워크 상태 확장 유틸리티
extension NetworkCheckerUtils on NetworkChecker {
  // 네트워크 사용 가능 여부 (모바일 데이터 절약 모드 고려)
  Future<bool> isNetworkAvailable({bool considerDataSaver = true}) async {
    if (!await isConnected()) return false;

    if (considerDataSaver) {
      final type = await getNetworkType();
      // 모바일 데이터일 때 추가 확인 로직
      if (type == NetworkType.mobile) {
        // TODO: 데이터 절약 모드 설정 확인
        return true; // 임시로 true 반환
      }
    }

    return true;
  }

  // 네트워크 상태 정보 종합
  Future<NetworkStatus> getNetworkStatus() async {
    final isConnected = await this.isConnected();
    final type = await getNetworkType();
    final quality = await testNetworkQuality();

    return NetworkStatus(
      isConnected: isConnected,
      type: type,
      quality: quality,
      timestamp: DateTime.now(),
    );
  }

  // 네트워크 대기 (연결될 때까지)
  Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (await isConnected()) {
        return;
      }
      await Future.delayed(checkInterval);
    }

    throw TimeoutException('네트워크 연결 대기 시간 초과', timeout);
  }
}
