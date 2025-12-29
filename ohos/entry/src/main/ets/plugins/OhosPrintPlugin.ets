import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  AbilityAware,
  AbilityPluginBinding,
} from '@ohos/flutter_ohos';
import print from '@ohos.print';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import fileUri from '@ohos.file.fileuri';

const TAG = "OhosPrintPlugin";
const CHANNEL_NAME = "com.cardflow.ohos_print";

/**
 * 鸿蒙原生打印插件
 * 通过 MethodChannel 接收 Flutter 端的打印请求
 * 实现了 AbilityAware 接口以获取 UIAbilityContext，从而能成功调起打印弹窗
 */
export default class OhosPrintPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private uiContext: common.UIAbilityContext | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "OhosPrintPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    console.info(TAG, "OhosPrintPlugin attached to engine");
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    console.info(TAG, "OhosPrintPlugin detached from engine");
  }

  // --- AbilityAware 接口实现 ---
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiContext = binding.getAbility().context as common.UIAbilityContext;
    console.info(TAG, "OhosPrintPlugin attached to ability");
  }

  onDetachedFromAbility(): void {
    this.uiContext = null;
    console.info(TAG, "OhosPrintPlugin detached from ability");
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    console.info(TAG, `Received method call: ${call.method}`);
    
    switch (call.method) {
      case "printImage":
        this.printImage(call, result);
        break;
      case "printPdf":
        this.printPdf(call, result);
        break;
      case "isSupported":
        result.success(true);
        break;
      default:
        result.notImplemented();
    }
  }

  /**
   * 打印图片
   */
  private printImage(call: MethodCall, result: MethodResult): void {
    try {
      const imageBytes = call.argument("imageBytes") as Uint8Array;
      const fileName = call.argument("fileName") as string || "card_print.png";
      
      if (!imageBytes || imageBytes.length === 0) {
        result.error("INVALID_ARGUMENT", "imageBytes is required", null);
        return;
      }

      this.saveAndPrint(imageBytes, fileName, result);

    } catch (e) {
      console.error(TAG, `printImage error: ${e}`);
      result.error("PRINT_ERROR", `${e}`, null);
    }
  }

  /**
   * 打印 PDF
   */
  private printPdf(call: MethodCall, result: MethodResult): void {
    try {
      const pdfBytes = call.argument("pdfBytes") as Uint8Array;
      const fileName = call.argument("fileName") as string || "card_print.pdf";
      
      if (!pdfBytes || pdfBytes.length === 0) {
        result.error("INVALID_ARGUMENT", "pdfBytes is required", null);
        return;
      }

      this.saveAndPrint(pdfBytes, fileName, result);

    } catch (e) {
      console.error(TAG, `printPdf error: ${e}`);
      result.error("PRINT_ERROR", `${e}`, null);
    }
  }

  /**
   * 保存文件并打印
   */
  private saveAndPrint(fileBytes: Uint8Array, fileName: string, result: MethodResult): void {
    if (!this.uiContext) {
      result.error("CONTEXT_NULL", "UIAbility context is null", null);
      return;
    }

    try {
      // 在 HarmonyOS NEXT 中，打印服务需要更好的访问性，使用 filesDir 相对更稳定
      const filesDir = this.uiContext.filesDir;
      const filePath = `${filesDir}/${fileName}`;
      
      // 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.truncateSync(file.fd); // 手动截断文件以确保是从头写入
      fs.writeSync(file.fd, fileBytes.buffer);
      fs.closeSync(file);
      
      console.info(TAG, `File saved to: ${filePath}`);

      // 获取文件 URI
      const uri = fileUri.getUriFromPath(filePath);
      const files: string[] = [uri];
      
      console.info(TAG, `Starting print with URI: ${uri}`);

      // 调用系统打印，必须传入 context 作为第二个参数
      print.print(files, this.uiContext).then(() => {
        console.info(TAG, "Print task submitted successfully");
        result.success(true);
      }).catch((err: Error) => {
        console.error(TAG, `Print failed: ${err.message}`);
        result.error("PRINT_FAILED", err.message, null);
      });

    } catch (e) {
      console.error(TAG, `saveAndPrint error: ${e}`);
      result.error("PRINT_ERROR", `${e}`, null);
    }
  }
}
