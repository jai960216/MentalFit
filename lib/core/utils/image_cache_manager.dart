import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheManager {
  static Widget getOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder:
          (context, url) =>
              placeholder ?? const Center(child: CircularProgressIndicator()),
      errorWidget:
          (context, url, error) =>
              errorWidget ?? const Icon(Icons.error_outline, color: Colors.red),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }

  static void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}
