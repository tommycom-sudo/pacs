import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'browser_page.dart';
import 'package:url_launcher/link.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MaterialApp(
    title: '语音叫号',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum TtsState { playing, stopped, paused, continued }

class _MyAppState extends State<MyApp> {
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 1.0;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  //String? _newVoiceText;
  int? _inputLength;

  TtsState ttsState = TtsState.stopped;

  bool get isPlaying => ttsState == TtsState.playing;
  bool get isStopped => ttsState == TtsState.stopped;
  bool get isPaused => ttsState == TtsState.paused;
  bool get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;
  var _url = new TextEditingController(); //获取叫号表和更新叫号状态
  var _setid = new TextEditingController();
  var _urljh = new TextEditingController(); //叫号屏地址前缀
  var _txtTest = new TextEditingController(); //测试获取号内容
  var _callCount = new TextEditingController(); //呼叫次数配置

  bool _isStop = false;
  late Timer _timer;

  @override
  initState() {
    super.initState();
    initTts();
    WidgetsFlutterBinding.ensureInitialized();
  }

  void _job() {
    if (!_isStop) {
      _doGet();
    }
  }

  _doGetTest() async {
    var response, url;
    try {
      url = Uri.parse(_url.text + "/getQueue/" + _setid.text);
      response = await http.get(url);
      print('请求服务');
    } catch (e) {
      _txtTest.text = e.toString();
    } finally {
      if (response.statusCode == 200) {
        _txtTest.text = response.body;
        await _success(response.body, true);
      } else {
        _txtTest.text = '失败:' + response.statusCode.toString() + response.body;
      }
    }
  }

  _doGet() async {
    //叫号
    var url = Uri.parse(_url.text + "/getQueue/" + _setid.text);
    var response = await http.get(url);
    if (response.statusCode == 200) {
      await _success(response.body, true);
    } else {
      print("失败"); //+ url.toString());
    }
  }

  Future<void> postData(queueId) async {
    var url = Uri.parse(_url.text + "/updateQueue");

    final response = await http.post(
      url, // 替换为你的API端点
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'queueId': queueId,
        // 更多键值对
      }),
    );

    if (response.statusCode == 200) {
      //print('请求成功：${response.body}');
    } else {
      print('请求失败，状态码：${response.statusCode}');
    }
  }

  Future<void> _success(String body, bool isNeedUtf8) async {
    var map = jsonDecode(body);
    int total = map['data'].length;
    int i = 0;

    while (i < total) {
      var s = '请 ' +
          //map['data'][i]["id"] +
          '[' +
          map['data'][i]["name"] +
          ']' +
          '到' +
          map['data'][i]["roomname"] +
          '检查';
      int callCount = int.tryParse(_callCount.text) ?? 3;
      await _speak(s, callCount);
      var queueid = map['data'][i]['queueid'];
      postData(queueid);
      i++;
    }

    // var decodeString = "";
    // map.forEach((key, value) {
    //   decodeString += "key: $key ------ value: $value\n";
    // });

    // print(decodeString);
  }

  dynamic initTts() async {
    flutterTts = FlutterTts();
    //读取默认值
    final url =
        await getUserConfig<String>('url', defaultValue: 'http://10.196.5.160');
    _url.text = url;
    final setid = await getUserConfig<String>('setid', defaultValue: '3');
    _setid.text = setid;
    final urljh = await getUserConfig<String>('urljh',
        defaultValue: 'http://10.196.5.143:8082');
    _urljh.text = urljh;
    final callCount =
        await getUserConfig<String>('callCount', defaultValue: '3');
    _callCount.text = callCount;

    final selectedEngine =
        await getUserConfig<String>('engine', defaultValue: '');
    await flutterTts.setEngine(selectedEngine);
    //engine = selectedEngine;
    setState(() {
      engine = selectedEngine;
    });
    //_url.text = "请 002 张小明到9号诊室"; //@taoqing
    //_newVoiceText = "测试 请 002 张小明到9号诊室";
    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
    _speak1();
  }

  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future<T> getUserConfig<T>(String key, {required defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    if (T == bool) {
      return prefs.getBool(key) ?? defaultValue;
    } else if (T == int) {
      return prefs.getInt(key) ?? defaultValue;
    } else if (T == double) {
      return prefs.getDouble(key) ?? defaultValue;
    } else if (T == String) {
      return prefs.getString(key) ?? defaultValue;
    } else {
      throw UnsupportedError('Unsupported type');
    }
  }

  Future<void> saveUserConfig(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      prefs.setBool(key, value);
    } else if (value is int) {
      prefs.setInt(key, value);
    } else if (value is double) {
      prefs.setDouble(key, value);
    } else if (value is String) {
      prefs.setString(key, value);
    } else {
      throw UnsupportedError('Unsupported type');
    }
  }

  //保存默认值
  Future<void> _save() async {
    await saveUserConfig('url', _url.text);
    await saveUserConfig('urljh', _urljh.text);
    await saveUserConfig('setid', _setid.text);
    await saveUserConfig('callCount', _callCount.text);
    await saveUserConfig('engine', engine);
    // if (_newVoiceText != null) {
    //   if (_newVoiceText!.isNotEmpty) {
    //     await flutterTts.speak(_newVoiceText!);
    //   }
    // }
  }
  // Future<void> _speak() async {
  //       Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (context) =>  WebRoute()),
  //           );
  // }

  void openLink(String url) async {
    try {
      // 尝试使用外部非浏览器应用模式（可能隐藏地址栏）
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      // 如果失败，回退到默认浏览器模式
      if (!await launchUrl(Uri.parse(url))) {
        throw 'Could not launch $url';
      }
    }
  }

  /// 语音播报和页面跳转的异步方法
  /// 该方法用于定时执行任务并打开指定URL
  Future<void> _speak1() async {
    // 设置停止标志为false，表示开始执行
    _isStop = false;

    // 创建一个定时器，每3秒执行一次_job方法
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _job();
    });

    /* 语音播报相关代码（已注释）
    // 设置语音播报的音量
    await flutterTts.setVolume(volume);
    // 设置语音播报的语速
    await flutterTts.setSpeechRate(rate);
    // 设置语音播报的音调
    await flutterTts.setPitch(pitch);

    // 检查是否有需要播报的文本
    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        // 执行语音播报
        await flutterTts.speak(_newVoiceText!);
      }
    }
    */

    // 示例URL：'http://192.168.0.193:8082/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=3'

    // 打开指定的URL链接
    // _urljh.text: 基础URL地址（从文本输入框获取）
    // _setid.text: 设置ID（从文本输入框获取）
    openLink(_urljh.text +
        '/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=' +
        _setid.text);

    /* 导航到WebView页面的替代方案（已注释）
    // 使用Navigator推入新的WebView页面
    // Navigator.push(
    //     context,
    //     //MaterialPageRoute(builder: (context) => WebviewWidget()),
    //     MaterialPageRoute(
    //         builder: (context) => BrowserPage(
    //             "http://192.168.0.193:8082/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=3")));
    */
  }

  //仅叫号
  Future<void> _speak2() async {
    _isStop = false;
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      _job();
    });
    /*
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
    */
  }

  Future<void> _speak(voiceText, count) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (voiceText != null) {
      if (voiceText!.isNotEmpty) {
        int i = 0;
        while (i < count) {
          await flutterTts.speak(voiceText!);
          i++;
        }
      }
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
    _isStop = true;
    _timer.cancel();
  }

  Future<void> _pause() async {
    await _speak("语音测试1，请 [徐海生] 到D啊8号诊室检查", 1);
    await _speak("语音测试2，请PX009 '徐海生' 到DR 8号诊室", 1);
    await _speak("语音测试3，请PX010 /徐海生/ 到Da阿 8号诊室", 1);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
    flutterTts.stop();
  }

  List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    setState(() {
      engine = selectedEngine;
    });
  }

  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      flutterTts.setLanguage(language!);
      if (isAndroid) {
        flutterTts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
  }

  // void _onChange(String text) {
  //   setState(() {
  //     _newVoiceText = text;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('语音叫号'),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              _inputSection(),
              _btnSection(),
              _engineSection(),
              _futureBuilder(),
              _buildSliders(),
              // if (isAndroid) _getMaxSpeechInputLengthSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _engineSection() {
    if (isAndroid) {
      return FutureBuilder<dynamic>(
          future: _getEngines(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return _enginesDropDownSection(snapshot.data as List<dynamic>);
            } else if (snapshot.hasError) {
              return Text('Error loading engines...');
            } else
              return Text('Loading engines...');
          });
    } else
      return Container(width: 0, height: 0);
  }

  Widget _futureBuilder() => FutureBuilder<dynamic>(
      future: _getLanguages(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return _languageDropDownSection(snapshot.data as List<dynamic>);
        } else if (snapshot.hasError) {
          return Text('Error loading languages...');
        } else
          return Text('Loading Languages...');
      });

  Widget _inputSection() => Container(
      padding: EdgeInsets.all(16.0),
      child: Column(children: [
        // 服务器配置卡片
        Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '服务器配置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: this._url,
                  decoration: InputDecoration(
                    labelText: '服务器地址',
                    hintText: '请输入API服务器地址',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: this._setid,
                  decoration: InputDecoration(
                    labelText: '设备ID',
                    hintText: '请输入设备标识',
                    prefixIcon: Icon(Icons.devices),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),

        // 显示配置卡片
        Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '显示配置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: this._urljh,
                  decoration: InputDecoration(
                    labelText: '叫号屏地址',
                    hintText: '请输入叫号显示页面地址',
                    prefixIcon: Icon(Icons.tv),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 语音配置卡片
        Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.volume_up, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      '语音配置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: this._callCount,
                  decoration: InputDecoration(
                    labelText: '呼叫次数',
                    hintText: '请输入呼叫次数（默认3次）',
                    prefixIcon: Icon(Icons.repeat),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),

        // 测试区域卡片
        Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      '测试区域',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: this._txtTest,
                  decoration: InputDecoration(
                    labelText: '测试结果',
                    hintText: '测试结果将显示在这里',
                    prefixIcon: Icon(Icons.info),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                  readOnly: true,
                ),
              ],
            ),
          ),
        ),
      ]));

  Widget _btnSection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 主要操作按钮
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        '主要操作',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.save,
                          label: '保存配置',
                          color: Colors.blue,
                          onPressed: _save,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.play_circle_filled,
                          label: '排队显示',
                          color: Colors.green,
                          onPressed: _speak1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.record_voice_over,
                          label: '仅叫号',
                          color: Colors.teal,
                          onPressed: _speak2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.stop_circle,
                          label: '停止',
                          color: Colors.red,
                          onPressed: _stop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 测试按钮
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        '测试功能',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.volume_up,
                          label: '发声测试',
                          color: Colors.orange,
                          onPressed: _pause,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildModernButton(
                          icon: Icons.network_check,
                          label: 'GET测试',
                          color: Colors.cyan,
                          onPressed: _doGetTest,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enginesDropDownSection(List<dynamic> engines) => Container(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_voice, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      '语音引擎',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      value: engine,
                      items: getEnginesDropDownMenuItems(engines),
                      onChanged: changedEnginesDropDownItem,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
                      hint: Text('选择语音引擎'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _languageDropDownSection(List<dynamic> languages) => Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.language, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    '语言设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: language,
                    items: getLanguageDropDownMenuItems(languages),
                    onChanged: changedLanguageDropDownItem,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.indigo),
                    hint: Text('选择语言'),
                  ),
                ),
              ),
              if (isAndroid) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isCurrentLanguageInstalled
                          ? Icons.check_circle
                          : Icons.error,
                      color: isCurrentLanguageInstalled
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isCurrentLanguageInstalled ? '语言已安装' : '语言未安装',
                      style: TextStyle(
                        color: isCurrentLanguageInstalled
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ));

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 3,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Column _buildButtonColumn(Color color, Color splashColor, IconData icon,
      String label, Function func) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: Icon(icon),
              color: color,
              splashColor: splashColor,
              onPressed: () => func()),
          Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: color)))
        ]);
  }

  Widget _getMaxSpeechInputLengthSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('Get max speech input length'),
          onPressed: () async {
            _inputLength = await flutterTts.getMaxSpeechInputLength;
            setState(() {});
          },
        ),
        Text("$_inputLength characters"),
      ],
    );
  }

  Widget _buildSliders() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text(
                    '语音参数调节',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _volume(),
              _pitch(),
              _rate(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _volume() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.volume_up, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              '音量: ${(volume * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.blue[100],
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withAlpha(32),
            valueIndicatorColor: Colors.blue,
          ),
          child: Slider(
            value: volume,
            onChanged: (newVolume) {
              setState(() => volume = newVolume);
            },
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: "${(volume * 100).round()}%",
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _pitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.graphic_eq, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Text(
              '音调: ${pitch.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.red[100],
            thumbColor: Colors.red,
            overlayColor: Colors.red.withAlpha(32),
            valueIndicatorColor: Colors.red,
          ),
          child: Slider(
            value: pitch,
            onChanged: (newPitch) {
              setState(() => pitch = newPitch);
            },
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: pitch.toStringAsFixed(1),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _rate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, size: 20, color: Colors.green),
            SizedBox(width: 8),
            Text(
              '语速: ${(rate * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.green[100],
            thumbColor: Colors.green,
            overlayColor: Colors.green.withAlpha(32),
            valueIndicatorColor: Colors.green,
          ),
          child: Slider(
            value: rate,
            onChanged: (newRate) {
              setState(() => rate = newRate);
            },
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: "${(rate * 100).round()}%",
          ),
        ),
      ],
    );
  }
}

class WebviewWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WebviewWidgetState();
}

class WebviewWidgetState extends State<WebviewWidget> {
  late final WebViewController _controller;
  @override
  void initState() {
    //controller = WebViewController()..loadRequest(Uri.parse('http://'));
    super.initState();
    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            openDialog(request);
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(
          'https://www.baidu.com/s?wd=test&rsv_spt=1&rsv_iqid=0xdba2c297001d98bf&issp=1&f=8&rsv_bp=1&rsv_idx=2&ie=utf-8&tn=baiduhome_pg&rsv_dl=tb&rsv_enter=1&rsv_sug3=5&rsv_sug1=4&rsv_sug7=100&rsv_sug2=0&rsv_btype=i&prefixsug=test&rsp=6&inputT=782&rsv_sug4=892'));
//'http://192.168.0.193:8082/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=3')
    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('叫号界面'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  Future<void> openDialog(HttpAuthRequest httpRequest) async {
    final TextEditingController usernameTextController =
        TextEditingController();
    final TextEditingController passwordTextController =
        TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${httpRequest.host}: ${httpRequest.realm ?? '-'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  autofocus: true,
                  controller: usernameTextController,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  controller: passwordTextController,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // Explicitly cancel the request on iOS as the OS does not emit new
            // requests when a previous request is pending.
            TextButton(
              onPressed: () {
                httpRequest.onCancel();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                httpRequest.onProceed(
                  WebViewCredential(
                    user: usernameTextController.text,
                    password: passwordTextController.text,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Authenticate'),
            ),
          ],
        );
      },
    );
  }
}
