import 'dart:typed_data';

/// 画布元素类型
enum CanvasItemType { text, image }

/// 画布元素基类
abstract class CanvasItem {
  final String id;
  final CanvasItemType type;
  
  /// 位置偏移
  double offsetX;
  double offsetY;
  
  /// 缩放比例
  double scale;
  
  /// 旋转角度（弧度）
  double rotation;

  CanvasItem({
    required this.id,
    required this.type,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scale = 1.0,
    this.rotation = 0,
  });
}

/// 图片元素
class ImageItem extends CanvasItem {
  /// 图片二进制数据
  final Uint8List imageBytes;
  
  /// 图片原始宽度（像素）
  final double originalWidth;
  
  /// 图片原始高度（像素）
  final double originalHeight;

  ImageItem({
    required super.id,
    required this.imageBytes,
    required this.originalWidth,
    required this.originalHeight,
    super.offsetX,
    super.offsetY,
    super.scale,
    super.rotation,
  }) : super(type: CanvasItemType.image);

  /// 复制并修改
  ImageItem copyWith({
    String? id,
    Uint8List? imageBytes,
    double? originalWidth,
    double? originalHeight,
    double? offsetX,
    double? offsetY,
    double? scale,
    double? rotation,
  }) {
    return ImageItem(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}
