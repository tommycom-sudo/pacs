# 语音叫号系统

一个基于Flutter开发的语音叫号应用，支持自动获取排队信息并进行语音播报。

## 主要功能

- **自动叫号**: 定时获取排队信息并进行语音播报
- **可配置呼叫次数**: 用户可自定义每次叫号的重复次数（默认3次）
- **配置管理**: 支持保存服务器地址、设备ID、叫号屏地址等配置
- **语音引擎选择**: 支持多种TTS语音引擎
- **实时显示**: 可同时打开叫号显示页面

## 环境配置

1.安装git  (注意<=2.8) ， 用 2.37会死活提示不行 Error: Unable to find git in your PATH.
2.安装flutter环境  (flutter_windows_3.38.4-stable)
3.配置flutter中国环境（两个全局变量 
PUB_HOSTED_URL=https://pub.flutter-io.cn
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

4.安装android studio  + sdK + 设置 ANDROID_HOME路径
   (androidstudio_yfdb_v2025.1.2.11_2265.com) 
5. c:\gradle\gradle-8.2-all.zip   (这个有代理可以处理吗？）

## 编译构建

```bash
cd c:\java\pacs
flutter build apk
```

可能错误：
flutter build apk
Flutter assets will be downloaded from https://storage.flutter-io.cn. Make sure you trust this source!
Upgrading build.gradle
e: file:///C:/Flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt:744:21 Unresolved reference: filePermissions
e: file:///C:/Flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt:745:25 Unresolved reference: user
e: file:///C:/Flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt:746:29 Unresolved reference: read
e: file:///C:/Flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt:747:29 Unresolved reference: write

FAILURE: Build failed with an exception.
原因：Flutter 3.38.4 需要 Java 17+
## 使用说明

1. **基础配置**:
   - 服务器地址: 设置获取排队信息的API地址
   - 设备ID: 设置当前设备的标识
   - 叫号屏地址: 设置显示页面的URL前缀
   - 呼叫次数: 设置每次叫号重复的次数

2. **操作步骤**:
   - 填写配置信息
   - 点击"保存配置"保存设置
   - 点击"排队显示"开始叫号并显示页面
   - 点击"仅叫号"只进行语音叫号
   - 点击"停止"结束叫号

3. **测试功能**:
   - "发声测试": 测试语音播报功能
   - "GET测试": 测试服务器连接
