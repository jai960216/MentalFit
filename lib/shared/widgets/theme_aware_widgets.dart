import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';

/// 테마를 인식하는 Container
class ThemedContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final bool useSurface; // true면 surface 색상, false면 background 색상
  final bool addShadow;
  final double? width;
  final double? height;

  const ThemedContainer({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.useSurface = true, // 기본적으로 surface 사용 (카드 같은 느낌)
    this.addShadow = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color:
            useSurface
                ? theme.colorScheme.surface
                : theme.scaffoldBackgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(16.r),
        boxShadow:
            addShadow
                ? [
                  BoxShadow(
                    color:
                        isDark
                            ? AppColors.darkCardShadow
                            : AppColors.grey400.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: child,
    );
  }
}

/// 테마를 인식하는 Card
class ThemedCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(16.r);
    final finalBorderRadius =
        borderRadius as BorderRadius? ?? defaultBorderRadius;

    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: finalBorderRadius),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: finalBorderRadius,
        child: card,
      );
    }

    return card;
  }
}

/// 테마를 인식하는 Text
class ThemedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isPrimary; // true면 primary text, false면 secondary text
  final bool isOnPrimary; // primary color 위의 텍스트인지 (예: 헤더)
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ThemedText({
    super.key,
    required this.text,
    this.style,
    this.isPrimary = true,
    this.isOnPrimary = false,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color textColor;
    if (isOnPrimary) {
      textColor = theme.colorScheme.onPrimary; // primary 색상 위의 텍스트
    } else if (isPrimary) {
      textColor = theme.colorScheme.onSurface; // 기본 텍스트
    } else {
      textColor = theme.colorScheme.onSurface.withOpacity(0.7); // 보조 텍스트
    }

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: textColor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 테마를 인식하는 Icon
class ThemedIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final bool isOnPrimary; // primary color 위의 아이콘인지
  final VoidCallback? onPressed;

  const ThemedIcon({
    super.key,
    required this.icon,
    this.size,
    this.isOnPrimary = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color =
        isOnPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    if (onPressed != null) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: size),
      );
    }

    return Icon(icon, color: color, size: size);
  }
}

/// 테마를 인식하는 Scaffold
class ThemedScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  const ThemedScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}

/// 테마를 인식하는 Divider
class ThemedDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final EdgeInsetsGeometry? margin;

  const ThemedDivider({super.key, this.height, this.thickness, this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height ?? 1,
      margin: margin,
      color: isDark ? AppColors.darkDivider : AppColors.divider,
    );
  }
}

/// 테마를 인식하는 Primary Container (예: 헤더)
class ThemedPrimaryContainer extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final bool useGradient;

  const ThemedPrimaryContainer({
    super.key,
    this.child,
    this.padding,
    this.borderRadius,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: useGradient ? AppColors.primaryGradient : null,
        color: useGradient ? null : theme.colorScheme.primary,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

/// 사용 예시를 위한 확장 메서드들
extension ThemeHelpers on BuildContext {
  /// 현재 테마의 primary 색상
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// 현재 테마의 surface 색상
  Color get surfaceColor => Theme.of(this).colorScheme.surface;

  /// 현재 테마의 배경 색상
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;

  /// 현재 테마의 텍스트 색상
  Color get textColor => Theme.of(this).colorScheme.onSurface;

  /// 현재 테마의 보조 텍스트 색상
  Color get secondaryTextColor =>
      Theme.of(this).colorScheme.onSurface.withOpacity(0.7);

  /// 다크모드 여부
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
