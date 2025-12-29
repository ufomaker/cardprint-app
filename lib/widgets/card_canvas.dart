import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../theme/liquid_glass_theme.dart';
import 'draggable_text.dart';

/// 卡片画布组件
/// 实现三段式布局：通过 Stack + Positioned 实现
class CardCanvas extends StatelessWidget {
  /// 用于截图的 GlobalKey
  final GlobalKey? captureKey;
  
  /// 是否为打印模式（移除阴影和圆角，确保内容填满纸张）
  final bool forPrint;

  const CardCanvas({
    super.key,
    this.captureKey,
    this.forPrint = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();
    final content = provider.content;

    // 打印模式：直接返回卡片内容，不包含 Center 和 margin
    // 这确保 RepaintBoundary 精确包裹卡片区域
    if (forPrint) {
      return RepaintBoundary(
        key: captureKey,
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              // 背景
              Positioned.fill(
                child: Container(color: Colors.white),
              ),
              
              // 内容层
              if (content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      // Header - 初始左上角
                      if (content.header.isNotEmpty)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: DraggableText(
                              text: content.header,
                              textAlign: TextAlign.left,
                              alignment: Alignment.topLeft,
                              blockType: TextBlockType.header,
                              padding: EdgeInsets.zero,
                              forPrint: true, // 打印模式使用纯黑色
                            ),
                          ),
                        ),

                      // Body - 初始居中
                      if (content.body.isNotEmpty)
                        Positioned.fill(
                          child: Center(
                            child: DraggableText(
                              text: content.body,
                              textAlign: TextAlign.center,
                              alignment: Alignment.center,
                              blockType: TextBlockType.body,
                              padding: EdgeInsets.zero,
                              forPrint: true, // 打印模式使用纯黑色
                            ),
                          ),
                        ),

                      // Footer - 初始右下角
                      if (content.footer.isNotEmpty)
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: DraggableText(
                              text: content.footer,
                              textAlign: TextAlign.right,
                              alignment: Alignment.bottomRight,
                              blockType: TextBlockType.footer,
                              padding: EdgeInsets.zero,
                              forPrint: true, // 打印模式使用纯黑色
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                _buildPlaceholder(),
            ],
          ),
        ),
      );
    }

    // 正常预览模式
    return RepaintBoundary(
      key: captureKey,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: (provider.paperSize.width > 0 && provider.paperSize.height > 0)
                ? provider.paperSize.width / provider.paperSize.height
                : 1.414, // 默认 A 系列纸张比例
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: LiquidGlassTheme.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // 背景
                    Positioned.fill(
                      child: Container(color: Colors.white),
                    ),
                
                // 内容层：使用 Positioned.fill 确保文字块在整个画布范围内接收手势
                if (content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Stack(
                      children: [
                        // Header - 初始左上角
                        if (content.header.isNotEmpty)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: DraggableText(
                                text: content.header,
                                textAlign: TextAlign.left,
                                alignment: Alignment.topLeft,
                                blockType: TextBlockType.header,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                        // Body - 初始居中
                        if (content.body.isNotEmpty)
                          Positioned.fill(
                            child: Center(
                              child: DraggableText(
                                text: content.body,
                                textAlign: TextAlign.center,
                                alignment: Alignment.center,
                                blockType: TextBlockType.body,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                        // Footer - 初始右下角
                        if (content.footer.isNotEmpty)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: DraggableText(
                                text: content.footer,
                                textAlign: TextAlign.right,
                                alignment: Alignment.bottomRight,
                                blockType: TextBlockType.footer,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  _buildPlaceholder(),

                // 对折贺卡折痕线指示
                if (provider.isFoldCard)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FoldLinePainter(),
                      ),
                    ),
                  ),

                // 对折贺卡封面标识
                if (provider.isFoldCard)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '↑ 封面（对折后在外侧）',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 自由模式提示
                if (provider.isFreeMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: LiquidGlassTheme.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_with, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '自由模式',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.content_paste_rounded,
            size: 48,
            color: LiquidGlassTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '粘贴或输入文案',
            style: TextStyle(
              color: LiquidGlassTheme.textSecondary.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持从微信、美团等 App 复制',
            style: TextStyle(
              color: LiquidGlassTheme.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 对折贺卡折痕线绘制器
class _FoldLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 在画布垂直中心绘制虚线
    final y = size.height / 2;
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
