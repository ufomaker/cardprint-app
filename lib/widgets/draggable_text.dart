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
enum EdgeType { top, bottom, left, right }

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
  bool _isResizing = false;
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

  // Handles resizing from 4 edges, calculating center shift dynamically
  void _handleEdgeResize(CardProvider provider, Offset globalDelta, {bool isLeft = false, bool isRight = false, bool isTop = false, bool isBottom = false}) {
    final rotation = _getRotation(provider);
    final cosR = cos(rotation);
    final sinR = sin(rotation);
    
    // Compute raw axis deltas based on screen touches, unrotated
    final localDx = globalDelta.dx * cosR + globalDelta.dy * sinR;
    final localDy = -globalDelta.dx * sinR + globalDelta.dy * cosR;

    double dw = 0;
    double dh = 0;

    if (isRight) dw = localDx;
    else if (isLeft) dw = -localDx;
    else if (isBottom) dh = localDy;
    else if (isTop) dh = -localDy;

    final currentW = _getWidth(provider);
    final currentH = _getHeight(provider);
    
    if (currentW == null || currentH == null) {
      _initSizeIfNeeded(provider);
      return;
    }

    final targetW = (currentW + dw).clamp(50.0, 10000.0);
    final targetH = (currentH + dh).clamp(30.0, 10000.0);

    final effectiveDw = targetW - currentW;
    final effectiveDh = targetH - currentH;

    if (effectiveDw == 0 && effectiveDh == 0) return;

    // Anchor resize logic - we move the center relative to the alignment origin
    final Alignment alignment = widget.alignment ?? Alignment.center;
    final ax = alignment.x;
    final ay = alignment.y;

    double shiftX = 0;
    double shiftY = 0;

    if (isRight) shiftX = effectiveDw * (ax + 1) / 2;
    else if (isLeft) shiftX = -effectiveDw * (1 - ax) / 2;
    else if (isBottom) shiftY = effectiveDh * (ay + 1) / 2;
    else if (isTop) shiftY = -effectiveDh * (1 - ay) / 2;

    _updateSize(provider, width: targetW, height: targetH);

    // Apply rotation back to the translation vector
    final dxGlobal = shiftX * cosR - shiftY * sinR;
    final dyGlobal = shiftX * sinR + shiftY * cosR;

    print("EdgeResize -> dx:\${globalDelta.dx.toStringAsFixed(1)}, dy:\${globalDelta.dy.toStringAsFixed(1)} | " 
          "growW:\${effectiveDw.toStringAsFixed(1)}, growH:\${effectiveDh.toStringAsFixed(1)} | "
          "shiftGlobal: \${dxGlobal.toStringAsFixed(1)}, \${dyGlobal.toStringAsFixed(1)} | edge: r\$isRight l\$isLeft b\$isBottom t\$isTop");

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

    const double handleRadius = 60.0;

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
                  if (_isResizing) return; // Don't translate while edge-resizing
                  if (details.pointerCount == 1) {
                    if (isFreeMode) {
                      _updateOffset(provider, details.focalPointDelta.dx, details.focalPointDelta.dy);
                    } else {
                      _updateOffset(provider, 0, details.focalPointDelta.dy);
                    }
                  } else if (isFreeMode && details.pointerCount >= 2) {
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
                child: Container(
                  key: _containerKey,
                  constraints: width == null 
                      ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7) 
                      : null,
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
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: Align(
                      alignment: widget.textAlign == TextAlign.center 
                          ? Alignment.topCenter 
                          : (widget.textAlign == TextAlign.right ? Alignment.topRight : Alignment.topLeft),
                      child: Text(
                        widget.text,
                        textAlign: widget.textAlign,
                        style: _getTextStyle(provider),
                        softWrap: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_isSelected && !widget.forPrint && isFreeMode) ...[
              // Floating Toolbar Above Text Box
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTonalButton(
                          icon: Icons.edit_rounded,
                          color: LiquidGlassTheme.secondaryColor,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onEdit?.call();
                          },
                        ),
                        Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                        _buildAlignmentRow(provider),
                        Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
                        _buildTonalButton(
                          icon: Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          onTap: () => _handleDelete(provider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4 Direction Resize Handles
              _buildEdgeDragHandle(provider, EdgeType.top),
              _buildEdgeDragHandle(provider, EdgeType.bottom),
              _buildEdgeDragHandle(provider, EdgeType.left),
              _buildEdgeDragHandle(provider, EdgeType.right),
            ]
          ],
        ),
      ),
    );
  }

  // Row for alignment controls inside floating toolbar
  Widget _buildAlignmentRow(CardProvider provider) {
    final currentAlign = _getCurrentAlign(provider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAlignButton(
          provider: provider,
          align: TextAlign.left,
          icon: Icons.format_align_left_rounded,
          isActive: currentAlign == TextAlign.left,
        ),
        _buildAlignButton(
          provider: provider,
          align: TextAlign.center,
          icon: Icons.format_align_center_rounded,
          isActive: currentAlign == TextAlign.center,
        ),
        _buildAlignButton(
          provider: provider,
          align: TextAlign.right,
          icon: Icons.format_align_right_rounded,
          isActive: currentAlign == TextAlign.right,
        ),
      ],
    );
  }

  // Tonal Button design for floating toolbar
  Widget _buildTonalButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  // 获取当前文字块的对齐方式
  TextAlign _getCurrentAlign(CardProvider provider) {
    switch (widget.blockType) {
      case TextBlockType.header: return provider.headerAlign;
      case TextBlockType.body: return provider.bodyAlign;
      case TextBlockType.footer: return provider.footerAlign;
    }
  }

  // 设置当前文字块的对齐方式
  void _setAlign(CardProvider provider, TextAlign align) {
    switch (widget.blockType) {
      case TextBlockType.header: provider.setHeaderAlign(align); break;
      case TextBlockType.body: provider.setBodyAlign(align); break;
      case TextBlockType.footer: provider.setFooterAlign(align); break;
    }
  }

  // 单个对齐按钮
  Widget _buildAlignButton({
    required CardProvider provider,
    required TextAlign align,
    required IconData icon,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _setAlign(provider, align);
      },
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? LiquidGlassTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : LiquidGlassTheme.textSecondary,
        ),
      ),
    );
  }

  // 4 Edge Resize Handle Builder
  Widget _buildEdgeDragHandle(CardProvider provider, EdgeType edge) {
    const double hitSize = 24.0;
    const double borderInset = 60.0; // The padding around the AnimatedContainer
    const double anchor = borderInset - hitSize / 2; // 48.0

    double? top, bottom, left, right;
    double? width, height;

    switch (edge) {
      case EdgeType.top:
        top = anchor;
        left = borderInset;
        right = borderInset;
        height = hitSize;
        break;
      case EdgeType.bottom:
        bottom = anchor;
        left = borderInset;
        right = borderInset;
        height = hitSize;
        break;
      case EdgeType.left:
        left = anchor;
        top = borderInset;
        bottom = borderInset;
        width = hitSize;
        break;
      case EdgeType.right:
        right = anchor;
        top = borderInset;
        bottom = borderInset;
        width = hitSize;
        break;
    }

    Widget visualHandle;
    if (edge == EdgeType.top || edge == EdgeType.bottom) {
      visualHandle = Center(
        child: Container(
          width: 32, height: 6,
          decoration: BoxDecoration(
            color: LiquidGlassTheme.primaryColor,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    } else {
      visualHandle = Center(
        child: Container(
          width: 6, height: 32,
          decoration: BoxDecoration(
            color: LiquidGlassTheme.primaryColor,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: (edge == EdgeType.left || edge == EdgeType.right) 
            ? SystemMouseCursors.resizeLeftRight 
            : SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            setState(() => _isResizing = true);
            _initSizeIfNeeded(provider);
            provider.saveToHistory();
          },
          onPanUpdate: (details) {
            _handleEdgeResize(
              provider, 
              details.delta, 
              isLeft: edge == EdgeType.left,
              isRight: edge == EdgeType.right,
              isTop: edge == EdgeType.top,
              isBottom: edge == EdgeType.bottom,
            );
          },
          onPanEnd: (details) {
            setState(() => _isResizing = false);
          },
          child: visualHandle,
        ),
      ),
    );
  }
}
