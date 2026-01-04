import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/card_content.dart';
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

  final VoidCallback? onEdit;

  const DraggableText({
    super.key,
    required this.text,
    required this.textAlign,
    required this.alignment,
    required this.blockType,
    this.padding,
    this.forPrint = false,
    this.onEdit,
  });

  @override
  State<DraggableText> createState() => _DraggableTextState();
}

class _DraggableTextState extends State<DraggableText> with SingleTickerProviderStateMixin {
  // ... (keep existing state variables)
  bool _isDragging = false;
  bool _isSelected = false;
  double _lastScale = 1.0;
  double _lastRotation = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final GlobalKey _containerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ... (keep _getTextStyle, _getWidth, _getHeight, _getOffsetX/Y/Scale/Rotation helpers)
  TextStyle _getTextStyle(CardProvider provider) {
     final textColor = widget.forPrint ? Colors.black : LiquidGlassTheme.textPrimary;
    
    final baseStyle = TextStyle(
      fontSize: provider.fontSize,
      color: textColor,
      height: 1.5,
      fontFamily: provider.fontFamily,
    );

    final googleFontsNames = ['Noto Serif SC', 'Noto Sans SC', 'ZCOOL XiaoWei'];
    if (googleFontsNames.contains(provider.fontFamily)) {
      try {
        return GoogleFonts.getFont(provider.fontFamily, textStyle: baseStyle);
      } catch (e) {
        return baseStyle;
      }
    }
    return baseStyle.copyWith(fontFamily: provider.fontFamily);
  }

  double? _getWidth(CardProvider provider) {
    CardContent content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: return content.headerWidth;
      case TextBlockType.body: return content.bodyWidth;
      case TextBlockType.footer: return content.footerWidth;
    }
  }

  double? _getHeight(CardProvider provider) {
    CardContent content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: return content.headerHeight;
      case TextBlockType.body: return content.bodyHeight;
      case TextBlockType.footer: return content.footerHeight;
    }
  }

  // Simplified _handleResize for strictly BR resizing
  void _handleResize(CardProvider provider, Offset delta) {
    final currentW = _getWidth(provider);
    final currentH = _getHeight(provider);
    
    if (currentW == null || currentH == null) {
      final box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final size = box.size;
        _updateSize(provider, width: currentW ?? size.width, height: currentH ?? size.height);
      }
      return;
    }

    // Always adding delta for BR resize
    final targetW = (currentW + delta.dx).clamp(50.0, 1000.0);
    final targetH = (currentH + delta.dy).clamp(20.0, 1000.0);

    final effectiveDw = targetW - currentW;
    final effectiveDh = targetH - currentH;

    _updateSize(provider, width: targetW, height: targetH);

    // Shift center by half delta to mimic corner drag
    // Rotated shift
    final shiftX = effectiveDw / 2;
    final shiftY = effectiveDh / 2;

    final rotation = _getRotation(provider);
    final cosR = cos(rotation);
    final sinR = sin(rotation);

    final dxGlobal = shiftX * cosR - shiftY * sinR;
    final dyGlobal = shiftX * sinR + shiftY * cosR;

    _updateOffset(provider, dxGlobal, dyGlobal);
  }
  
  void _updateSize(CardProvider provider, {double? width, double? height}) {
    switch (widget.blockType) {
      case TextBlockType.header: provider.updateHeaderSize(width: width, height: height); break;
      case TextBlockType.body: provider.updateBodySize(width: width, height: height); break;
      case TextBlockType.footer: provider.updateFooterSize(width: width, height: height); break;
    }
  }

  void _initSizeIfNeeded(CardProvider provider) {
    if (_getWidth(provider) == null || _getHeight(provider) == null) {
      final box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final size = box.size;
        _updateSize(provider, width: size.width, height: size.height);
      }
    }
  }

  // ... (keep _getOffset/Transform helpers)
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

  void _handleDelete(CardProvider provider) {
    CardContent content = provider.content;
    switch (widget.blockType) {
      case TextBlockType.header: content = content.copyWith(header: ''); break;
      case TextBlockType.body: content = content.copyWith(body: ''); break;
      case TextBlockType.footer: content = content.copyWith(footer: ''); break;
    }
    provider.updateContent(content);
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
    
    final width = _getWidth(provider);
    final height = _getHeight(provider);

    const double handleRadius = 24.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(offsetX, offsetY)
          ..rotateZ(rotation)
          ..scale(baseScale),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(handleRadius),
              child: GestureDetector(
                onTap: () {
                  if (!widget.forPrint && isFreeMode) {
                    setState(() => _isSelected = !_isSelected);
                    HapticFeedback.selectionClick();
                  }
                },
                onScaleStart: (details) {
                  provider.saveToHistory();
                  setState(() => _isDragging = true);
                  _animationController.forward();
                  HapticFeedback.lightImpact();
                  _lastScale = 1.0;
                  _lastRotation = 0.0;
                },
                onScaleUpdate: (details) {
                  if (isFreeMode) {
                    _updateOffset(provider, details.focalPointDelta.dx, details.focalPointDelta.dy);
                  } else {
                    _updateOffset(provider, 0, details.focalPointDelta.dy);
                  }

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
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  key: _containerKey,
                  duration: const Duration(milliseconds: 100), 
                  width: width,
                  height: height,
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDragging 
                        ? LiquidGlassTheme.primaryColor.withOpacity(0.08) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDragging
                          ? LiquidGlassTheme.primaryColor.withOpacity(0.5)
                          : (_isSelected && !widget.forPrint)
                              ? LiquidGlassTheme.primaryColor.withOpacity(0.5)
                              : isFreeMode && !widget.forPrint
                                  ? Colors.grey.withOpacity(0.15)
                                  : Colors.transparent,
                      width: (_isDragging || _isSelected) ? 2.0 : 1.0,
                    ),
                  ),
                  child: Text(
                    widget.text,
                    textAlign: widget.textAlign,
                    style: _getTextStyle(provider),
                  ),
                ),
              ),
            ),

            if (_isSelected && !widget.forPrint && isFreeMode) ...[
               // Top-Left: Delete
              _buildControlButton(
                alignment: Alignment.topLeft,
                icon: Icons.close_rounded,
                color: Colors.red.shade400,
                onTap: () => _handleDelete(provider),
              ),
              
              // Top-Right: Edit
              _buildControlButton(
                alignment: Alignment.topRight,
                icon: Icons.edit_rounded,
                color: LiquidGlassTheme.secondaryColor,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onEdit?.call();
                },
              ),

              // Bottom-Right: Resize
              _buildResizeHandle(provider),
            ]
          ],
        ),
      ),
    );
  }

  // Generic Control Button Builder (for Delete and Edit)
  Widget _buildControlButton({
    required Alignment alignment,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;
    
    return Positioned(
      top: isTop ? 0 : null,
      bottom: !isTop ? 0 : null,
      left: isLeft ? 0 : null,
      right: !isLeft ? 0 : null,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Simplified BR Resize Handle
  Widget _buildResizeHandle(CardProvider provider) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, 
        onPanStart: (details) => _initSizeIfNeeded(provider),
        onPanUpdate: (details) => _handleResize(provider, details.delta),
        child: Container(
          width: 48, 
          height: 48,
          alignment: Alignment.center,
          color: Colors.transparent, 
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: LiquidGlassTheme.primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.crop_free_rounded, 
              size: 14,
              color: LiquidGlassTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
