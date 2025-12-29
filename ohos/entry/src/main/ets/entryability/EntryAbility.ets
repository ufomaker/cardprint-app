
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import OhosPrintPlugin from '../plugins/OhosPrintPlugin';
import OhosPreferencesPlugin from '../plugins/OhosPreferencesPlugin';
import OhosClipboardPlugin from '../plugins/OhosClipboardPlugin';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    
    // 手动注册鸿蒙原生插件（避免被 flutter build 覆盖）
    flutterEngine.getPlugins()?.add(new OhosPrintPlugin())
    flutterEngine.getPlugins()?.add(new OhosPreferencesPlugin())
    flutterEngine.getPlugins()?.add(new OhosClipboardPlugin())
    console.info("EntryAbility", "Plugins registered manually")
  }
}
