import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/canvas_item.dart';
import '../providers/card_provider.dart';
import '../theme/liquid_glass_theme.dart';

/// 可拖拽图片组件
/// 支持拖拽移动、双指缩放旋转
class DraggableImage extends StatefulWidget {
  final ImageItem imageItem;
  final bool forPrint;

  const DraggableImage({
    super.key,
    required this.imageItem,
    this.forPrint = false,
  });

  @override
  State<DraggableImage> createState() => _DraggableImageState();
}

class _DraggableImageState extends State<DraggableImage>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isSelected = false;

  // 用于手势缓存
  double _lastScale = 1.0;
  double _lastRotation = 0.0;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();
    final isFreeMode = provider.isFreeMode;
    final item = widget.imageItem;

    // 计算显示尺寸（限制最大初始宽度为画布宽度的60%）
    final maxInitialWidth = 200.0;
    final aspectRatio = item.originalWidth / item.originalHeight;
    double displayWidth = item.originalWidth > maxInitialWidth
        ? maxInitialWidth
        : item.originalWidth;
    double displayHeight = displayWidth / aspectRatio;

    // 手柄触摸区域半径
    const double handleRadius = 24.0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(item.offsetX, item.offsetY)
          ..rotateZ(item.rotation)
          ..scale(item.scale),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(handleRadius),
              child: GestureDetector(
                onTap: () {
                  if (!widget.forPrint) {
                    setState(() => _isSelected = !_isSelected);
                    HapticFeedback.selectionClick();
                  }
                },
                onScaleStart: (details) {
                  if (widget.forPrint) return;
                  provider.saveToHistory();
                  setState(() => _isDragging = true);
                  _animationController.forward();
                  HapticFeedback.lightImpact();
                  _lastScale = 1.0;
                  _lastRotation = 0.0;
                },
                onScaleUpdate: (details) {
                  if (widget.forPrint) return;
                  // 处理位移
                  if (isFreeMode) {
                    provider.updateImageOffset(
                      item.id,
                      details.focalPointDelta.dx,
                      details.focalPointDelta.dy,
                    );
                  } else {
                    provider.updateImageOffset(
                      item.id,
                      0,
                      details.focalPointDelta.dy,
                    );
                  }

                  // 处理多指变换（仅自由模式）
                  if (isFreeMode && details.pointerCount >= 2) {
                    if (details.scale != 1.0) {
                      final scaleDelta = details.scale / _lastScale;
                      provider.updateImageTransform(item.id, scaleDelta: scaleDelta);
                      _lastScale = details.scale;
                    }
                    if (details.rotation != 0) {
                      final rotationDelta = details.rotation - _lastRotation;
                      provider.updateImageTransform(item.id,
                          rotationDelta: rotationDelta);
                      _lastRotation = details.rotation;
                    }
                  }
                },
                onScaleEnd: (details) {
                  if (widget.forPrint) return;
                  setState(() => _isDragging = false);
                  _animationController.reverse();
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
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
                    boxShadow: _isDragging
                        ? [
                            BoxShadow(
                              color:
                                  LiquidGlassTheme.primaryColor.withOpacity(0.15),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      item.imageBytes,
                      width: displayWidth,
                      height: displayHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // 选中状态下的控件
            if (_isSelected && !widget.forPrint) ...[
              // 删除按钮 (Top-Left)
              Positioned(
                top: 0,
                left: 0,
                child: GestureDetector(
                  onTap: () {
                     HapticFeedback.mediumImpact();
                     context.read<CardProvider>().removeImage(widget.imageItem.id);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 缩放手柄 (Bottom-Right, 仅自由模式)
              if (isFreeMode)
                _buildResizeHandle(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle(CardProvider provider) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          // 均匀缩放逻辑
          // 仅处理右下角拖拽: dx > 0 or dy > 0 应该放大
          final dx = details.delta.dx;
          final dy = details.delta.dy;
          
          // 使用简单的平均值作为缩放驱动
          final scaleChange = (dx + dy);
          
          final sensitivity = 0.005;
          final scaleDelta = 1.0 + scaleChange * sensitivity;
          
          provider.updateImageTransform(widget.imageItem.id, scaleDelta: scaleDelta);
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
