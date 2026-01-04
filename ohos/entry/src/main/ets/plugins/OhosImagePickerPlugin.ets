import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

const TAG = "OhosImagePickerPlugin";
const CHANNEL_NAME = "com.cardflow.ohos_image_picker";

/**
 * 鸿蒙原生图片选择器插件
 * 使用 PhotoViewPicker 实现图片选择功能
 * 注意：拍照功能暂时使用相册选择代替
 */
export default class OhosImagePickerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "OhosImagePickerPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    console.info(TAG, "OhosImagePickerPlugin attached to engine");
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    console.info(TAG, "OhosImagePickerPlugin detached from engine");
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    console.info(TAG, `Received method call: ${call.method}`);
    
    switch (call.method) {
      case "pickFromGallery":
        this.pickFromGallery(result);
        break;
      case "pickFromCamera":
        // 暂时使用相册选择代替拍照
        console.info(TAG, "pickFromCamera: Using gallery as fallback");
        this.pickFromGallery(result);
        break;
      default:
        result.notImplemented();
    }
  }

  /**
   * 从相册选择图片
   */
  private async pickFromGallery(result: MethodResult): Promise<void> {
    try {
      console.info(TAG, "pickFromGallery: Opening photo picker");
      
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const uri = photoSelectResult.photoUris[0];
        console.info(TAG, `pickFromGallery: Selected URI = ${uri}`);
        
        // 读取图片数据
        const imageData = await this.readImageFromUri(uri);
        if (imageData) {
          result.success(imageData);
        } else {
          result.error("READ_ERROR", "Failed to read image data", null);
        }
      } else {
        console.info(TAG, "pickFromGallery: No image selected");
        result.success(null);
      }
    } catch (e) {
      const error = e as BusinessError;
      console.error(TAG, `pickFromGallery error: ${error.message}`);
      result.error("PICK_ERROR", error.message, null);
    }
  }

  /**
   * 从 URI 读取图片并返回数据以及宽高信息
   * 媒体库 URI 需要使用 fd 方式读取
   */
  private async readImageFromUri(uri: string): Promise<Record<string, Object> | null> {
    let file: fs.File | null = null;
    try {
      console.info(TAG, `readImageFromUri: Reading from ${uri}`);
      
      // 使用 fs.open 打开媒体库文件
      file = await fs.open(uri, fs.OpenMode.READ_ONLY);
      console.info(TAG, `readImageFromUri: File opened, fd = ${file.fd}`);
      
      // 使用 fd 获取文件状态
      const stat = await fs.stat(file.fd);
      const fileSize = stat.size;
      console.info(TAG, `readImageFromUri: File size = ${fileSize}`);
      
      // 读取文件内容
      const arrayBuffer = new ArrayBuffer(fileSize);
      const readLen = await fs.read(file.fd, arrayBuffer);
      console.info(TAG, `readImageFromUri: Read ${readLen} bytes`);
      
      // 关闭文件
      await fs.close(file);
      file = null;
      
      // 获取图片尺寸
      const imageSource = image.createImageSource(arrayBuffer);
      const imageInfo = await imageSource.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;
      console.info(TAG, `readImageFromUri: Image size = ${width}x${height}`);
      
      // 转换为 Uint8Array 并转为数组
      const uint8Array = new Uint8Array(arrayBuffer);
      const bytesArray: number[] = [];
      for (let i = 0; i < uint8Array.length; i++) {
        bytesArray.push(uint8Array[i]);
      }
      
      // 返回 Record 包含字节数据和尺寸
      const resultRecord: Record<string, Object> = {
        "bytes": bytesArray,
        "width": width,
        "height": height
      };
      
      return resultRecord;
    } catch (e) {
      const error = e as BusinessError;
      console.error(TAG, `readImageFromUri error: ${error.message}`);
      // 确保关闭文件
      if (file != null) {
        try {
          await fs.close(file);
        } catch (closeErr) {
          console.error(TAG, `Failed to close file: ${closeErr}`);
        }
      }
      return null;
    }
  }
}


