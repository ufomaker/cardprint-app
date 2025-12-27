import 'dart:ui';
import 'package:flutter/material.dart';

/// HarmonyOS 鸿蒙风格主题 - 宇宙蓝/雪原灰
class LiquidGlassTheme {
  // HarmonyOS 核心配色：宇宙蓝 + 雪原灰
  static const Color primaryColor = Color(0xFF007DFF); // HarmonyOS 宇宙蓝
  static const Color secondaryColor = Color(0xFF0A59F7); // HarmonyOS 品牌蓝
  static const Color accentColor = Color(0xFF1F2937); // 深灰（强调色）
  
  // 雪原灰系列背景
  static const Color backgroundStart = Color(0xFFF7F9FC); // 极浅灰蓝
  static const Color backgroundEnd = Color(0xFFF1F3F5); // 雪原灰
  
  // 文字颜色（HarmonyOS 规范）
  static const Color textPrimary = Color(0xFF182431); // 一级文字
  static const Color textSecondary = Color(0xFF66727A); // 二级文字

  /// 渐变背景 (HarmonyOS 雪原灰渐变)
  static const BoxDecoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF7F9FC), // 顶部极浅
        Color(0xFFEEF2F6), // 中部过渡
        Color(0xFFF1F3F5), // 底部雪原灰
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  /// 卡片投影
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.03),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  /// 玻璃容器样式
  static BoxDecoration glassDecoration({
    double blur = 15.0,
    double opacity = 0.7,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// 全局 ThemeData
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      onPrimary: Colors.white, // 确保主按钮上的文字是白色
    ),
    scaffoldBackgroundColor: backgroundStart,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

/// 玻璃效果容器组件
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity),
                  Colors.white.withOpacity(opacity * 0.7),
                ],
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
