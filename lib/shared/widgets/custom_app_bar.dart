import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? backgroundColor;
  final Color? titleColor;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double? elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.titleColor,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.elevation,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.white,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions,
      bottom: bottom,
      iconTheme: IconThemeData(color: titleColor ?? AppColors.textPrimary),
    );
  }

  Widget? _buildBackButton(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop) return null;

    return IconButton(
      icon: Icon(Icons.arrow_back_ios, size: 20.w),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

// === 투명한 AppBar (스크롤 시 배경 변경용) ===
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? titleColor;

  const TransparentAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: titleColor ?? AppColors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(color: titleColor ?? AppColors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// === 그라데이션 AppBar ===
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Color> gradientColors;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? titleColor;

  const GradientAppBar({
    super.key,
    required this.title,
    this.gradientColors = const [AppColors.primary, AppColors.secondary],
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppColors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
        iconTheme: IconThemeData(color: titleColor ?? AppColors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// === 검색 기능이 있는 AppBar ===
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const SearchAppBar({
    super.key,
    required this.title,
    this.hintText = '검색어를 입력하세요',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.actions,
    this.backgroundColor,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  bool _isSearching = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          _isSearching
              ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(fontSize: 16.sp, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
                onChanged: widget.onSearchChanged,
                onSubmitted: (_) => widget.onSearchSubmitted?.call(),
              )
              : Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
      backgroundColor: widget.backgroundColor ?? AppColors.white,
      elevation: 0,
      leading:
          _isSearching
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _stopSearch,
              )
              : null,
      actions:
          _isSearching
              ? [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearchChanged?.call('');
                  },
                ),
              ]
              : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
                ...?widget.actions,
              ],
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }
}
