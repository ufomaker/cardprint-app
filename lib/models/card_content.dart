/// 卡片内容数据模型
/// 包含三段式结构：称呼(header)、正文(body)、落款(footer)
class CardContent {
  /// 称呼/抬头，例如："亲爱的老婆："
  String header;

  /// 正文内容
  String body;

  /// 落款，例如："爱你的老公\n2025.12.25"
  String footer;

  /// 文字块的位置偏移（Y 轴用于锁定模式，X/Y 用于自由模式）
  double headerOffsetX;
  double headerOffsetY;
  double bodyOffsetX;
  double bodyOffsetY;
  double footerOffsetX;
  double footerOffsetY;

  /// 文字块的缩放比例（自由模式）
  double headerScale;
  double bodyScale;
  double footerScale;

  /// 文字块的旋转角度（弧度，自由模式）
  double headerRotation;
  double bodyRotation;
  double footerRotation;

  /// 文字块的尺寸（为空则自适应）
  double? headerWidth;
  double? headerHeight;
  double? bodyWidth;
  double? bodyHeight;
  double? footerWidth;
  double? footerHeight;

  CardContent({
    this.header = '',
    this.body = '',
    this.footer = '',
    this.headerOffsetX = 0,
    this.headerOffsetY = 0,
    this.bodyOffsetX = 0,
    this.bodyOffsetY = 0,
    this.footerOffsetX = 0,
    this.footerOffsetY = 0,
    this.headerScale = 1.0,
    this.bodyScale = 1.0,
    this.footerScale = 1.0,
    this.headerRotation = 0,
    this.bodyRotation = 0,
    this.footerRotation = 0,
    this.headerWidth,
    this.headerHeight,
    this.bodyWidth,
    this.bodyHeight,
    this.footerWidth,
    this.footerHeight,
  });

  /// 从原始文本解析（规则版）
  /// 规则：第一行为 header，最后一行为 footer，中间为 body
  factory CardContent.fromText(String text) {
    final lines = text.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      return CardContent();
    }
    
    if (lines.length == 1) {
      return CardContent(body: lines[0]);
    }
    
    if (lines.length == 2) {
      return CardContent(
        header: lines[0],
        body: lines[1],
      );
    }
    
    // 多于两行：首行为 header，末行为 footer，中间为 body
    return CardContent(
      header: lines.first,
      body: lines.sublist(1, lines.length - 1).join('\n'),
      footer: lines.last,
    );
  }

  /// 检查内容是否为空
  bool get isEmpty => header.isEmpty && body.isEmpty && footer.isEmpty;

  /// 检查内容是否非空
  bool get isNotEmpty => !isEmpty;

  /// 复制并修改
  CardContent copyWith({
    String? header,
    String? body,
    String? footer,
    double? headerOffsetX,
    double? headerOffsetY,
    double? bodyOffsetX,
    double? bodyOffsetY,
    double? footerOffsetX,
    double? footerOffsetY,
    double? headerScale,
    double? bodyScale,
    double? footerScale,
    double? headerRotation,
    double? bodyRotation,
    double? footerRotation,
    double? headerWidth,
    double? headerHeight,
    double? bodyWidth,
    double? bodyHeight,
    double? footerWidth,
    double? footerHeight,
  }) {
    return CardContent(
      header: header ?? this.header,
      body: body ?? this.body,
      footer: footer ?? this.footer,
      headerOffsetX: headerOffsetX ?? this.headerOffsetX,
      headerOffsetY: headerOffsetY ?? this.headerOffsetY,
      bodyOffsetX: bodyOffsetX ?? this.bodyOffsetX,
      bodyOffsetY: bodyOffsetY ?? this.bodyOffsetY,
      footerOffsetX: footerOffsetX ?? this.footerOffsetX,
      footerOffsetY: footerOffsetY ?? this.footerOffsetY,
      headerScale: headerScale ?? this.headerScale,
      bodyScale: bodyScale ?? this.bodyScale,
      footerScale: footerScale ?? this.footerScale,
      headerRotation: headerRotation ?? this.headerRotation,
      bodyRotation: bodyRotation ?? this.bodyRotation,
      footerRotation: footerRotation ?? this.footerRotation,
      headerWidth: headerWidth ?? this.headerWidth,
      headerHeight: headerHeight ?? this.headerHeight,
      bodyWidth: bodyWidth ?? this.bodyWidth,
      bodyHeight: bodyHeight ?? this.bodyHeight,
      footerWidth: footerWidth ?? this.footerWidth,
      footerHeight: footerHeight ?? this.footerHeight,
    );
  }

  @override
  String toString() {
    return 'CardContent(header: $header, body: $body, footer: $footer)';
  }
}
