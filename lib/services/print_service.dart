import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/card_content.dart';

/// 打印服务
/// 负责 PDF 生成和打印调用
class PrintService {
  /// 将 Widget 截图为图片（用于 Emoji 光栅化）
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 8.0); // 8倍分辨率确保打印无锯齿
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('截图失败: $e');
      return null;
    }
  }

  /// 高分辨率截图（用于打印，不额外放大，因为画布已按正确尺寸渲染）
  static Future<Uint8List?> captureWidgetHighRes(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // 使用1.0像素比，因为画布已经按照300DPI计算的正确尺寸渲染
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('高分辨率截图失败: $e');
      return null;
    }
  }

  /// 生成 PDF 文档
  static Future<Uint8List> generatePdf({
    required CardContent content,
    required Size paperSizeMm,
    required String fontFamily,
    required double fontSize,
    required bool isFoldCard,
    Uint8List? cardImage,
  }) async {
    final pdf = pw.Document();

    // 使用标准A4尺寸（210mm x 297mm）作为PDF页面格式
    // 因为Android系统无法正确接收自定义纸张尺寸
    const a4Width = 210.0; // mm
    const a4Height = 297.0; // mm
    final pageFormat = PdfPageFormat(
      a4Width * PdfPageFormat.mm,
      a4Height * PdfPageFormat.mm,
    );

    if (cardImage != null) {
      // 使用光栅化的图片（包含 Emoji）
      final image = pw.MemoryImage(cardImage);
      
      // 将毫米转换为点
      final cardWidthPt = paperSizeMm.width * PdfPageFormat.mm;
      final cardHeightPt = paperSizeMm.height * PdfPageFormat.mm;
      
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            // 单页和对折贺卡都映射到A4纸的顶部居中位置
            // 对折贺卡：用户打印后自行对折纸张，预览中已有折痕线提示
            return pw.Align(
              alignment: pw.Alignment.topCenter, // 横向居中，纵向置顶
              child: pw.Container(
                width: cardWidthPt,
                height: cardHeightPt,
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain, // 使用contain避免拉伸变形
                ),
              ),
            );
          },
        ),
      );
    } else {
      // 纯文本模式（无 Emoji）
      // 将毫米转换为点
      final cardWidthPt = paperSizeMm.width * PdfPageFormat.mm;
      final cardHeightPt = paperSizeMm.height * PdfPageFormat.mm;
      
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            // 单页和对折贺卡都映射到A4纸的顶部居中位置
            return pw.Align(
              alignment: pw.Alignment.topCenter, // 横向居中，纵向置顶
              child: pw.Container(
                width: cardWidthPt,
                height: cardHeightPt,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(color: PdfColors.white),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Header - 顶格左对齐
                    if (content.header.isNotEmpty)
                      pw.Container(
                        alignment: pw.Alignment.topLeft,
                        child: pw.Text(
                          content.header,
                          style: pw.TextStyle(fontSize: fontSize),
                        ),
                      ),
                    
                    pw.Spacer(),
                    
                    // Body - 居中
                    if (content.body.isNotEmpty)
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          content.body,
                          style: pw.TextStyle(fontSize: fontSize),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    
                    pw.Spacer(),
                    
                    // Footer - 右下对齐
                    if (content.footer.isNotEmpty)
                      pw.Container(
                        alignment: pw.Alignment.bottomRight,
                        child: pw.Text(
                          content.footer,
                          style: pw.TextStyle(fontSize: fontSize),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// 打印 PDF
  static Future<bool> printPdf(
    Uint8List pdfBytes, {
    required Size paperSizeMm,
    String jobName = 'CardFlow 贺卡',
  }) async {
    try {
      // 由于Android系统无法正确接收自定义纸张尺寸
      // 统一使用标准A4格式，贺卡内容已在PDF生成时映射到A4纸上
      const a4Format = PdfPageFormat.a4;
      
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: jobName,
        format: a4Format,
      );
      return true;
    } catch (e) {
      debugPrint('打印失败: $e');
      return false;
    }
  }

  /// 预览 PDF
  static Future<void> sharePdf(Uint8List pdfBytes, {String filename = 'cardflow_card.pdf'}) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
