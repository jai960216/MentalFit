import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager {
  static final ImageCacheManager instance = ImageCacheManager._internal();
  ImageCacheManager._internal();

  // 기본 캐시 매니저
  static final DefaultCacheManager defaultCacheManager = DefaultCacheManager();

  // 메모리 캐시 크기 제한 (100MB)
  static const int maxCacheSize = 100 * 1024 * 1024;

  // 이미지 최적화 옵션
  static Widget getOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration? cacheDuration,
    bool useOldImageOnUrlChange = true,
  }) {
    debugPrint('🖼️ ImageCacheManager: 이미지 로딩 시작 - $imageUrl');

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: defaultCacheManager,
      placeholder: (context, url) {
        debugPrint('⏳ ImageCacheManager: 로딩 중 - $url');
        return placeholder ?? const Center(child: CircularProgressIndicator());
      },
      errorWidget: (context, url, error) {
        debugPrint('❌ ImageCacheManager: 로딩 실패 - $url, 오류: $error');
        return errorWidget ??
            const Icon(Icons.error_outline, color: Colors.red);
      },
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  // 캐시 초기화
  static Future<void> clearCache() async {
    await defaultCacheManager.emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  // 특정 이미지 캐시 삭제
  static Future<void> removeFromCache(String url) async {
    await defaultCacheManager.removeFile(url);
  }

  // 캐시 크기 확인 (현재는 단순히 캐시가 있는지 여부만 확인)
  static Future<bool> hasCache() async {
    try {
      final cacheDir = await defaultCacheManager.store.retrieveCacheData('');
      return cacheDir != null;
    } catch (e) {
      debugPrint('캐시 확인 중 오류 발생: $e');
      return false;
    }
  }

  // 캐시 정리
  static Future<void> trimCache() async {
    try {
      if (await hasCache()) {
        await defaultCacheManager.emptyCache();
      }
    } catch (e) {
      debugPrint('캐시 정리 중 오류 발생: $e');
    }
  }
}
