
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos';
import pasteboard from '@ohos.pasteboard';
import { BusinessError } from '@ohos.base';
import OhosClipboardPlugin from '../plugins/OhosClipboardPlugin';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";
  
  // 监听显示粘贴对话框的请求
  @StorageLink('ShowPasteDialog') showPasteDialog: boolean = false;

  build() {
    Stack() {
      // 1. Flutter 页面作为底层
      Column() {
        FlutterPage({ viewId: this.viewId })
      }
      .width('100%')
      .height('100%')

      // 2. 粘贴对话框遮罩层
      if (this.showPasteDialog) {
        Column() {
          // 对话框内容
          Column() {
            Text("允许粘贴")
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
            
            Text("CardPrint 申请读取剪贴板内容以导入文本")
              .fontSize(16)
              .fontColor('#666666')
              .margin({ bottom: 20 })
              .textAlign(TextAlign.Center)

            Row() {
              // 取消按钮
              Button("取消")
                .fontColor('#666666')
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  OhosClipboardPlugin.onPasteReceived(null);
                })
                .margin({ right: 20 })

              // 粘贴按钮 (安全控件)
              PasteButton({
                text: 0, // PasteButtonText.PASTE = 0
                buttonType: ButtonType.Capsule,
              })
                .onClick(async (event, result) => {
                  if (result == 0) { // PasteButtonOnClickResult.SUCCESS = 0
                    try {
                      const systemPasteboard = pasteboard.getSystemPasteboard();
                      const pasteData = await systemPasteboard.getData();
                      const text = pasteData.getPrimaryText();
                      OhosClipboardPlugin.onPasteReceived(text);
                    } catch (e) {
                      console.error("PasteButton error: " + e);
                      OhosClipboardPlugin.onPasteReceived(null);
                    }
                  } else {
                    console.info("PasteButton click failed: " + result);
                    // OhosClipboardPlugin.onPasteReceived(null); // 可以选择是否立即关闭，或者让用户重试
                  }
                })
            }
          }
          .backgroundColor(Color.White)
          .padding(24)
          .borderRadius(16)
          .width('80%')
          .shadow({ radius: 10, color: '#40000000', offsetY: 5 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000') // 半透明背景
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          // 点击遮罩层关闭? 最好保持模态
        })
      }
    }
  }

  onBackPress(): boolean {
    // 如果对话框显示中，按返回键关闭对话框
    if (this.showPasteDialog) {
      OhosClipboardPlugin.onPasteReceived(null);
      return true;
    }
    
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}