import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import pasteboard from '@ohos.pasteboard';

const TAG = "OhosClipboardPlugin";
const CHANNEL_NAME = "com.cardflow.ohos_clipboard";

/**
 * 鸿蒙原生剪贴板插件
 * 使用 AppStorage 通知 UI 显示 PasteButton 对话框
 */
export default class OhosClipboardPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private static pendingResult: MethodResult | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "OhosClipboardPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    console.info(TAG, "OhosClipboardPlugin attached to engine");
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    console.info(TAG, "OhosClipboardPlugin detached from engine");
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    console.info(TAG, `Received method call: ${call.method}`);
    
    switch (call.method) {
      case "getText":
        this.getText(result);
        break;
      case "setText":
        this.setText(call, result);
        break;
      case "hasText":
        this.hasText(result);
        break;
      default:
        result.notImplemented();
    }
  }

  /**
   * 接收来自 UI 的粘贴数据
   */
  public static onPasteReceived(text: string | null) {
    if (OhosClipboardPlugin.pendingResult) {
      if (text !== null) {
        OhosClipboardPlugin.pendingResult.success(text);
      } else {
        OhosClipboardPlugin.pendingResult.success(""); // 或者是 null，视 Dart 端处理而定
      }
      OhosClipboardPlugin.pendingResult = null;
    }
    // 关闭对话框
    AppStorage.setOrCreate('ShowPasteDialog', false);
  }

  /**
   * 读取剪贴板文本 (触发 UI 对话框)
   */
  private async getText(result: MethodResult): Promise<void> {
    try {
      // 检查是否已有挂起的请求
      if (OhosClipboardPlugin.pendingResult) {
        console.warn(TAG, "getText: Request already in progress");
        result.error("BUSY", "Request in progress", null);
        return;
      }

      console.info(TAG, "getText: Requesting PasteButton dialog");
      OhosClipboardPlugin.pendingResult = result;
      
      // 通过 AppStorage 通知 Index.ets 显示粘贴对话框
      AppStorage.setOrCreate('ShowPasteDialog', true);
      
    } catch (e) {
      console.error(TAG, `getText error: ${e}`);
      result.error("ERROR", `${e}`, null);
    }
  }

  /**
   * 设置剪贴板文本 (无需权限)
   */
  private async setText(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const text = call.argument("text") as string;
      if (!text) {
        result.success(false);
        return;
      }

      const systemPasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      await systemPasteboard.setData(pasteData);
      
      console.info(TAG, `setText: success, length=${text.length}`);
      result.success(true);
    } catch (e) {
      console.error(TAG, `setText error: ${e}`);
      result.success(false);
    }
  }

  /**
   * 检查剪贴板是否有文本 (可能需要权限，暂时返回 false 或尝试读取)
   * 由于无法静默读取，这里可能无法准确判断，除非使用 PasteButton
   * 这里的实现仅供参考，可能在无权限时失效
   */
  private async hasText(result: MethodResult): Promise<void> {
    try {
      // 鸿蒙 NEXT 无法在无权限下检查 hasData
      // 只能返回 false，或者修改 Dart 端逻辑不依赖此方法
      result.success(true); // 假装有数据，强制走 getText -> PasteButton 流程?
    } catch (e) {
      console.error(TAG, `hasText error: ${e}`);
      result.success(false);
    }
  }
}
