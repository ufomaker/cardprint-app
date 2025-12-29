import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../services/print_service.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/card_canvas.dart';
import '../widgets/clipboard_dialog.dart';
import '../widgets/settings_dialog.dart'; // 导入设置弹窗

/// 主屏幕
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey _canvasKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  
  String? _lastClipboardText;
  bool _showClipboardDialog = false;
  String _clipboardText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;

      if (text != null && 
          text.isNotEmpty && 
          text != _lastClipboardText) {
        setState(() {
          _clipboardText = text;
          _showClipboardDialog = true;
        });
      }
    } catch (e) {
      debugPrint('读取剪贴板失败: $e');
    }
  }

  void _handleClipboardConfirm() async {
    final provider = context.read<CardProvider>();
    _lastClipboardText = _clipboardText;
    setState(() {
      _showClipboardDialog = false;
    });
    HapticFeedback.mediumImpact();
    await provider.parseAndUpdateContent(_clipboardText);
  }

  void _handleClipboardDismiss() {
    _lastClipboardText = _clipboardText;
    setState(() {
      _showClipboardDialog = false;
    });
  }

  Future<void> _handlePrint() async {
    final provider = context.read<CardProvider>();
    
    if (provider.content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入内容')),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    
    // 创建一个临时的打印专用画布（无阴影、无margin、无圆角）
    final printCanvasKey = GlobalKey();
    OverlayEntry? overlayEntry;
    
    // 使用与屏幕预览相同的逻辑像素尺寸渲染
    // 然后通过高像素比截图来获得高分辨率打印质量
    // 这确保字体大小和间距与屏幕预览完全一致
    final screenWidth = MediaQuery.of(context).size.width - 32; // 减去margin
    final aspectRatio = provider.paperSize.width / provider.paperSize.height;
    final canvasWidth = screenWidth;
    final canvasHeight = screenWidth / aspectRatio;
    
    try {
      // 在屏幕外渲染打印画布，使用与屏幕预览相同的尺寸
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000, // 移到屏幕外
          top: 0,
          child: Material(
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: CardCanvas(
                captureKey: printCanvasKey,
                forPrint: true,
              ),
            ),
          ),
        ),
      );
      
      Overlay.of(context).insert(overlayEntry);
      
      // 等待渲染完成
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 使用高像素比截图以获得高分辨率打印质量
      final imageBytes = await PrintService.captureWidget(printCanvasKey);
      
      // 所有平台统一流程：生成 PDF 后打印
      // PDF 会将卡片内容正确映射到 A4 纸的顶部居中位置
      final pdfBytes = await PrintService.generatePdf(
        content: provider.content,
        paperSizeMm: provider.paperSize,
        fontFamily: provider.fontFamily,
        fontSize: provider.fontSize,
        isFoldCard: provider.isFoldCard,
        cardImage: imageBytes,
      );

      // 调用打印（鸿蒙和其他平台都使用 PDF）
      final success = await PrintService.printPdf(
        pdfBytes,
        paperSizeMm: provider.paperSize,
      );
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打印失败，请重试')),
        );
      }
    } finally {
      // 移除临时overlay
      overlayEntry?.remove();
    }
  }

  void _showInputDialog() {
    final provider = context.read<CardProvider>();
    _textController.text = [
      provider.content.header,
      provider.content.body,
      provider.content.footer,
    ].where((s) => s.isNotEmpty).join('\n');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '输入文案',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LiquidGlassTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 6,
                autofocus: true,
                style: const TextStyle(fontSize: 16, color: LiquidGlassTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: '描述收信人、祝福语、落款...',
                  hintStyle: TextStyle(color: LiquidGlassTheme.textSecondary.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: LiquidGlassTheme.primaryColor.withOpacity(0.05),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  await provider.parseAndUpdateContent(_textController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LiquidGlassTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: LiquidGlassTheme.primaryColor.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(provider.useAI ? Icons.auto_awesome : Icons.text_fields, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      provider.useAI ? 'AI 智能排版' : '普通平铺',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示页面设置弹窗
  void _showSettingsDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => const Center(
        child: SettingsDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CardFlow',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: LiquidGlassTheme.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            if (provider.useAI) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LiquidGlassTheme.primaryColor, LiquidGlassTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: LiquidGlassTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // 重置
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: LiquidGlassTheme.textPrimary),
            tooltip: '重置位置',
            onPressed: () {
              HapticFeedback.mediumImpact();
              provider.resetTransforms();
            },
          ),
          // AI 开关
          IconButton(
            icon: Icon(
              provider.useAI ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: provider.useAI ? LiquidGlassTheme.primaryColor : LiquidGlassTheme.textPrimary,
            ),
            tooltip: 'AI 模式',
            onPressed: () {
              HapticFeedback.selectionClick();
              provider.toggleAI();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.useAI ? '已开启 AI 智能解析' : '已切换为普通分段模式'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings_input_composite_rounded, color: LiquidGlassTheme.textPrimary),
            tooltip: '纸张设置',
            onPressed: _showSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: LiquidGlassTheme.gradientBackground,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                   // 卡片预览区
                  Expanded(
                    child: CardCanvas(captureKey: _canvasKey),
                  ),

                  // 底部工具栏
                  _buildToolbar(provider),
                ],
              ),

              // 剪贴板检测对话框 (移至更高层，避免被挡住)
              if (_showClipboardDialog)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 100, // 改为顶部弹出更显眼，不挡住工具栏
                  child: ClipboardDialog(
                    previewText: _clipboardText,
                    onConfirm: _handleClipboardConfirm,
                    onDismiss: _handleClipboardDismiss,
                  ),
                ),

              // 加载状态遮罩
              if (provider.isLoading)
                Container(
                  color: Colors.white.withOpacity(0.5),
                  child: Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(40),
                      blur: 25,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(LiquidGlassTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'AI 智绘排版',
                            style: TextStyle(
                              color: LiquidGlassTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(CardProvider provider) {
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // 输入按钮
          _ToolbarSquareAction(
            icon: Icons.add_comment_rounded,
            onTap: _showInputDialog,
            color: LiquidGlassTheme.primaryColor,
          ),

          const SizedBox(width: 16),

          // 字体
          Expanded(
            child: _ToolbarTextAction(
              icon: Icons.text_fields_rounded,
              label: '字体',
              onTap: () {
                HapticFeedback.selectionClick();
                _showFontPicker(provider);
              },
            ),
          ),

          // 字号
          Expanded(
            child: _ToolbarTextAction(
              icon: Icons.format_size_rounded,
              label: '${provider.fontSize.toInt()}',
              onTap: () {
                HapticFeedback.selectionClick();
                _showFontSizePicker(provider);
              },
            ),
          ),

          // 撤回按钮
          Expanded(
            child: _ToolbarTextAction(
              icon: Icons.undo_rounded,
              label: '撤回',
              onTap: provider.canUndo ? () {
                HapticFeedback.selectionClick();
                provider.undo();
              } : null,
              isActive: provider.canUndo,
            ),
          ),

          // 模式
          Expanded(
            child: _ToolbarTextAction(
              icon: provider.isFreeMode ? Icons.open_with_rounded : Icons.lock_outline_rounded,
              label: provider.isFreeMode ? '自由' : '锁定',
              onTap: () {
                HapticFeedback.mediumImpact();
                provider.toggleMode();
              },
              isActive: provider.isFreeMode,
            ),
          ),

          const SizedBox(width: 12),

          // 打印按钮 - 强化对比度
          Material(
            color: LiquidGlassTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            shadowColor: LiquidGlassTheme.primaryColor.withOpacity(0.4),
            child: InkWell(
              onTap: _handlePrint,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '打印',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontPicker(CardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '书写风格',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LiquidGlassTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.availableFonts.length,
                itemBuilder: (context, index) {
                  final font = provider.availableFonts[index];
                  final isSelected = font == provider.fontFamily;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    title: Text(
                      provider.fontDisplayNames[font] ?? font,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 18,
                        color: isSelected ? LiquidGlassTheme.primaryColor : LiquidGlassTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: LiquidGlassTheme.primaryColor) : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      provider.setFont(font);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 32, indent: 24, endIndent: 24),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: LiquidGlassTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.file_upload_outlined, color: LiquidGlassTheme.primaryColor),
              ),
              title: const Text('从手机导入新字体', style: TextStyle(color: LiquidGlassTheme.primaryColor, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                final success = await provider.importFont();
                if (success && mounted) {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('字体导入成功！')));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFontSizePicker(CardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.zoom_in_rounded, color: LiquidGlassTheme.textPrimary),
                  SizedBox(width: 12),
                  Text('字号调节', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 32),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: LiquidGlassTheme.primaryColor,
                  inactiveTrackColor: LiquidGlassTheme.primaryColor.withOpacity(0.1),
                  thumbColor: LiquidGlassTheme.primaryColor,
                  overlayColor: LiquidGlassTheme.primaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: provider.fontSize,
                  min: 12,
                  max: 48,
                  onChanged: (value) {
                    provider.setFontSize(value);
                    setModalState(() {});
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${provider.fontSize.toInt()} px',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: LiquidGlassTheme.primaryColor),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 底部工具栏方形操作按钮
class _ToolbarSquareAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ToolbarSquareAction({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }
}

/// 底部工具栏文字操作项
class _ToolbarTextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolbarTextAction({required this.icon, required this.label, this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isActive 
        ? LiquidGlassTheme.primaryColor 
        : (isEnabled ? LiquidGlassTheme.textSecondary : LiquidGlassTheme.textSecondary.withOpacity(0.4));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
