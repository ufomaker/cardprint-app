import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../theme/liquid_glass_theme.dart';

/// 文字块类型枚举
enum TextBlockType { header, body, footer }

/// 可拖拽文字块组件
/// 支持 Y 轴锁定拖拽和自由模式下的双指缩放旋转
class DraggableText extends StatefulWidget {
  final String text;
  final TextAlign textAlign;
  final Alignment alignment;
  final TextBlockType blockType;
  final EdgeInsetsGeometry? padding;
  final bool forPrint; // 打印模式：使用纯黑色

  const DraggableText({
    super.key,
    required this.text,
    required this.textAlign,
    required this.alignment,
    required this.blockType,
    this.padding,
    this.forPrint = false,
  });

  @override
  State<DraggableText> createState() => _DraggableTextState();
}

class _DraggableTextState extends State<DraggableText> with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  
  // 用于手势缓存
  double _lastScale = 1.0;
  double _lastRotation = 0.0;

  // 动画控制器，用于选中时的缩放效果
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  TextStyle _getTextStyle(CardProvider provider) {
    // 打印模式使用纯黑色，屏幕预览使用主题的深蓝灰色
    final textColor = widget.forPrint ? Colors.black : LiquidGlassTheme.textPrimary;
    
    final baseStyle = TextStyle(
      fontSize: provider.fontSize,
      color: textColor,
      height: 1.5,
      fontFamily: provider.fontFamily,
      // 移除白色阴影以确保打印文字清晰不发淡
    );

    // 检查是否是内置 Google Fonts
    final googleFontsNames = ['Noto Serif SC', 'Noto Sans SC', 'ZCOOL XiaoWei'];
    if (googleFontsNames.contains(provider.fontFamily)) {
      try {
        return GoogleFonts.getFont(provider.fontFamily, textStyle: baseStyle);
      } catch (e) {
        return baseStyle;
      }
    }

    // 内置本地字体（通过 pubspec.yaml 注册）
    final builtInFonts = ['千图小兔体', '一叶知秋行楷', '田英章硬笔楷书', '迷你简启体'];
    if (builtInFonts.contains(provider.fontFamily)) {
      return baseStyle.copyWith(fontFamily: provider.fontFamily);
    }

    // 自定义导入的字体或其他情况
    return baseStyle.copyWith(fontFamily: provider.fontFamily);
  }

  // 获取当前块的变换属性
  double _getOffsetX(CardProvider provider) {
    final content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: return content.headerOffsetX;
      case TextBlockType.body: return content.bodyOffsetX;
      case TextBlockType.footer: return content.footerOffsetX;
    }
  }

  double _getOffsetY(CardProvider provider) {
    final content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: return content.headerOffsetY;
      case TextBlockType.body: return content.bodyOffsetY;
      case TextBlockType.footer: return content.footerOffsetY;
    }
  }

  double _getScale(CardProvider provider) {
    final content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: return content.headerScale;
      case TextBlockType.body: return content.bodyScale;
      case TextBlockType.footer: return content.footerScale;
    }
  }

  double _getRotation(CardProvider provider) {
    final content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: return content.headerRotation;
      case TextBlockType.body: return content.bodyRotation;
      case TextBlockType.footer: return content.footerRotation;
    }
  }

  void _updateOffset(CardProvider provider, double dx, double dy) {
    switch (widget.blockType) {
      case TextBlockType.header: provider.updateHeaderOffset(dx, dy); break;
      case TextBlockType.body: provider.updateBodyOffset(dx, dy); break;
      case TextBlockType.footer: provider.updateFooterOffset(dx, dy); break;
    }
  }

  void _updateTransform(CardProvider provider, {double? scale, double? rotation}) {
    switch (widget.blockType) {
      case TextBlockType.header: provider.updateHeaderTransform(scale: scale, rotation: rotation); break;
      case TextBlockType.body: provider.updateBodyTransform(scale: scale, rotation: rotation); break;
      case TextBlockType.footer: provider.updateFooterTransform(scale: scale, rotation: rotation); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    final provider = context.watch<CardProvider>();
    final isFreeMode = provider.isFreeMode;
    
    final offsetX = _getOffsetX(provider);
    final offsetY = _getOffsetY(provider);
    final baseScale = _getScale(provider);
    final rotation = _getRotation(provider);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(offsetX, offsetY)
          ..rotateZ(rotation)
          ..scale(baseScale),
        alignment: Alignment.center,
        child: GestureDetector(
          onScaleStart: (details) {
            // 保存当前状态到历史栈以支持撤回
            provider.saveToHistory();
            setState(() => _isDragging = true);
            _animationController.forward();
            HapticFeedback.lightImpact(); // 开始拖拽时的触感
            _lastScale = 1.0;
            _lastRotation = 0.0;
          },
          onScaleUpdate: (details) {
            // 1. 处理位移
            if (isFreeMode) {
              _updateOffset(provider, details.focalPointDelta.dx, details.focalPointDelta.dy);
            } else {
              _updateOffset(provider, 0, details.focalPointDelta.dy);
            }

            // 2. 处理多指变换
            if (isFreeMode && details.pointerCount >= 2) {
              if (details.scale != 1.0) {
                final scaleDelta = details.scale / _lastScale;
                _updateTransform(provider, scale: scaleDelta);
                _lastScale = details.scale;
              }
              if (details.rotation != 0) {
                final rotationDelta = details.rotation - _lastRotation;
                _updateTransform(provider, rotation: rotationDelta);
                _lastRotation = details.rotation;
              }
            }
          },
          onScaleEnd: (details) {
            setState(() => _isDragging = false);
            _animationController.reverse();
            HapticFeedback.selectionClick(); // 结束时的触感
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isDragging 
                  ? LiquidGlassTheme.primaryColor.withOpacity(0.08) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDragging
                    ? LiquidGlassTheme.primaryColor.withOpacity(0.5)
                    : isFreeMode 
                        ? Colors.grey.withOpacity(0.15)
                        : Colors.transparent,
                width: _isDragging ? 2.0 : 1.0,
              ),
              boxShadow: _isDragging ? [
                BoxShadow(
                  color: LiquidGlassTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            child: Text(
              widget.text,
              textAlign: widget.textAlign,
              style: _getTextStyle(provider),
            ),
          ),
        ),
      ),
    );
  }
}
