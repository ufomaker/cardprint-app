import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const TAG = "OhosPreferencesPlugin";
const CHANNEL_NAME = "com.cardflow.ohos_preferences";
const PREFERENCES_NAME = "cardflow_settings";

/**
 * 鸿蒙原生持久化存储插件
 * 使用 @ohos.data.preferences 实现键值对存储
 */
export default class OhosPreferencesPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "OhosPreferencesPlugin";
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext() as common.UIAbilityContext;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    console.info(TAG, "OhosPreferencesPlugin attached to engine");
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    this.context = null;
    console.info(TAG, "OhosPreferencesPlugin detached from engine");
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    console.info(TAG, `Received method call: ${call.method}`);
    
    switch (call.method) {
      case "setString":
        this.setString(call, result);
        break;
      case "getString":
        this.getString(call, result);
        break;
      case "setInt":
        this.setInt(call, result);
        break;
      case "getInt":
        this.getInt(call, result);
        break;
      case "setDouble":
        this.setDouble(call, result);
        break;
      case "getDouble":
        this.getDouble(call, result);
        break;
      case "setBool":
        this.setBool(call, result);
        break;
      case "getBool":
        this.getBool(call, result);
        break;
      case "remove":
        this.remove(call, result);
        break;
      case "clear":
        this.clear(result);
        break;
      default:
        result.notImplemented();
    }
  }

  private async getPreferences(): Promise<preferences.Preferences | null> {
    if (!this.context) {
      return null;
    }
    try {
      return await preferences.getPreferences(this.context, PREFERENCES_NAME);
    } catch (e) {
      console.error(TAG, `Failed to get preferences: ${e}`);
      return null;
    }
  }

  private async setString(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const value = call.argument("value") as string;
      const prefs = await this.getPreferences();
      if (prefs) {
        await prefs.put(key, value);
        await prefs.flush();
        result.success(true);
      } else {
        result.error("PREFS_NULL", "Preferences instance is null", null);
      }
    } catch (e) {
      console.error(TAG, `setString error: ${e}`);
      result.error("SET_ERROR", `${e}`, null);
    }
  }

  private async getString(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const defaultValue = call.argument("defaultValue") as string || "";
      const prefs = await this.getPreferences();
      if (prefs) {
        const value = await prefs.get(key, defaultValue);
        result.success(value);
      } else {
        result.success(defaultValue);
      }
    } catch (e) {
      console.error(TAG, `getString error: ${e}`);
      result.success(call.argument("defaultValue") || "");
    }
  }

  private async setInt(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const value = call.argument("value") as number;
      const prefs = await this.getPreferences();
      if (prefs) {
        await prefs.put(key, value);
        await prefs.flush();
        result.success(true);
      } else {
        result.error("PREFS_NULL", "Preferences instance is null", null);
      }
    } catch (e) {
      console.error(TAG, `setInt error: ${e}`);
      result.error("SET_ERROR", `${e}`, null);
    }
  }

  private async getInt(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const prefs = await this.getPreferences();
      if (prefs) {
        // 先检查键是否存在
        const hasKey = await prefs.has(key);
        if (!hasKey) {
          result.success(null);
          return;
        }
        const value = await prefs.get(key, 0);
        result.success(value);
      } else {
        result.success(null);
      }
    } catch (e) {
      console.error(TAG, `getInt error: ${e}`);
      result.success(null);
    }
  }

  private async setDouble(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const value = call.argument("value") as number;
      const prefs = await this.getPreferences();
      if (prefs) {
        await prefs.put(key, value);
        await prefs.flush();
        result.success(true);
      } else {
        result.error("PREFS_NULL", "Preferences instance is null", null);
      }
    } catch (e) {
      console.error(TAG, `setDouble error: ${e}`);
      result.error("SET_ERROR", `${e}`, null);
    }
  }

  private async getDouble(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      console.info(TAG, `getDouble: key=${key}`);
      const prefs = await this.getPreferences();
      if (prefs) {
        // 先检查键是否存在
        const hasKey = await prefs.has(key);
        console.info(TAG, `getDouble: key=${key}, hasKey=${hasKey}`);
        if (!hasKey) {
          console.info(TAG, `getDouble: key=${key} not found, returning null`);
          result.success(null);
          return;
        }
        const value = await prefs.get(key, 0.0);
        console.info(TAG, `getDouble: key=${key}, value=${value}`);
        result.success(value);
      } else {
        console.error(TAG, `getDouble: prefs is null for key=${key}`);
        result.success(null);
      }
    } catch (e) {
      console.error(TAG, `getDouble error: ${e}`);
      result.success(null);
    }
  }

  private async setBool(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const value = call.argument("value") as boolean;
      const prefs = await this.getPreferences();
      if (prefs) {
        await prefs.put(key, value);
        await prefs.flush();
        result.success(true);
      } else {
        result.error("PREFS_NULL", "Preferences instance is null", null);
      }
    } catch (e) {
      console.error(TAG, `setBool error: ${e}`);
      result.error("SET_ERROR", `${e}`, null);
    }
  }

  private async getBool(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const prefs = await this.getPreferences();
      if (prefs) {
        // 先检查键是否存在
        const hasKey = await prefs.has(key);
        if (!hasKey) {
          result.success(null);
          return;
        }
        const value = await prefs.get(key, false);
        result.success(value);
      } else {
        result.success(null);
      }
    } catch (e) {
      console.error(TAG, `getBool error: ${e}`);
      result.success(null);
    }
  }

  private async remove(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const key = call.argument("key") as string;
      const prefs = await this.getPreferences();
      if (prefs) {
        await prefs.delete(key);
        await prefs.flush();
        result.success(true);
      } else {
        result.error("PREFS_NULL", "Preferences instance is null", null);
      }
    } catch (e) {
      console.error(TAG, `remove error: ${e}`);
      result.error("REMOVE_ERROR", `${e}`, null);
    }
  }

  private async clear(result: MethodResult): Promise<void> {
    try {
      const prefs = await this.getPreferences();
      if (prefs) {
        await prefs.clear();
        await prefs.flush();
        result.success(true);
      } else {
        result.error("PREFS_NULL", "Preferences instance is null", null);
      }
    } catch (e) {
      console.error(TAG, `clear error: ${e}`);
      result.error("CLEAR_ERROR", `${e}`, null);
    }
  }
}
