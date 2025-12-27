import 'package:flutter/material.dart';
import '../theme/liquid_glass_theme.dart';

/// 剪贴板检测弹窗
class ClipboardDialog extends StatelessWidget {
  final String previewText;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const ClipboardDialog({
    super.key,
    required this.previewText,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // 截取预览文本（最多 50 字符）
    final preview = previewText.length > 50
        ? '${previewText.substring(0, 50)}...'
        : previewText;

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.content_paste_go_rounded,
                    color: LiquidGlassTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '检测到新文案',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: LiquidGlassTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '点击智能识别排版',
                        style: TextStyle(
                          fontSize: 13,
                          color: LiquidGlassTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    color: LiquidGlassTheme.textSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 预览文本
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: LiquidGlassTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Text(
                preview,
                style: const TextStyle(
                  fontSize: 14,
                  color: LiquidGlassTheme.textPrimary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 20),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '忽略',
                      style: TextStyle(color: LiquidGlassTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LiquidGlassTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: LiquidGlassTheme.primaryColor.withOpacity(0.4),
                    ),
                    child: const Text(
                      '一键生成贺卡',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // 显式设置文字颜色
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
