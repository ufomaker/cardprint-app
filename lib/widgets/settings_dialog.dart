import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';
import '../theme/liquid_glass_theme.dart';

/// 设置弹窗 - 支持自定义尺寸
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CardProvider>();
    _widthController = TextEditingController(text: provider.customWidth.toInt().toString());
    _heightController = TextEditingController(text: provider.customHeight.toInt().toString());
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();

    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings_suggest_rounded, color: LiquidGlassTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    '页面设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: LiquidGlassTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text(
                '贺卡纸张尺寸 (单位: mm)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: LiquidGlassTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              
              // 纸张尺寸列表
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.presetPaperSizes.entries.map((entry) {
                  final isSelected = (provider.isCustomSize && entry.key == '自定义') ||
                                     (!provider.isCustomSize && provider.paperSize == entry.value && entry.key != '自定义');
                  
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      provider.setPaperSize(entry.value);
                      
                      // 强制同步输入框数值，确保切换时显示正确
                      if (provider.isCustomSize) {
                         // 如果切换到自定义，显示当前的自定义缓存值
                        _widthController.text = provider.customWidth.toInt().toString();
                        _heightController.text = provider.customHeight.toInt().toString();
                      } else {
                        // 如果切换到预设，显示预设值
                        _widthController.text = entry.value.width.toInt().toString();
                        _heightController.text = entry.value.height.toInt().toString();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? LiquidGlassTheme.primaryColor 
                            : LiquidGlassTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? LiquidGlassTheme.primaryColor 
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: isSelected ? Colors.white : LiquidGlassTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 20),

              // 自定义尺寸输入框
              if (provider.isCustomSize)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LiquidGlassTheme.primaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('宽度(W)', style: TextStyle(fontSize: 12, color: LiquidGlassTheme.textSecondary)),
                            TextField(
                              controller: _widthController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(suffixText: 'mm', border: InputBorder.none),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              onChanged: (val) {
                                final w = double.tryParse(val);
                                if (w != null) provider.updateCustomWidth(w);
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: LiquidGlassTheme.primaryColor.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('高度(H)', style: TextStyle(fontSize: 12, color: LiquidGlassTheme.textSecondary)),
                            TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(suffixText: 'mm', border: InputBorder.none),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              onChanged: (val) {
                                final h = double.tryParse(val);
                                if (h != null) provider.updateCustomHeight(h);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              
              // 贺卡类型开关
              SwitchListTile(
                title: const Text('对折贺卡模式', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('对折贺卡从距顶部一个卡片高度处开始打印', style: TextStyle(fontSize: 12)),
                value: provider.isFoldCard,
                activeColor: LiquidGlassTheme.primaryColor,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  provider.setFoldCard(val);
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // AI 模式开关
              SwitchListTile(
                title: const Text('AI 智能排版模式', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('自动分析分段', style: TextStyle(fontSize: 12)),
                value: provider.useAI,
                activeColor: LiquidGlassTheme.primaryColor,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  provider.toggleAI();
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 16),
              
              // 完成按钮
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('完成设置', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
