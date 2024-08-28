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
    try{
      url = Uri.parse(_url.text + "/getQueue/" + _setid.text);
      response = await http.get(url);
      print('请求服务');
    }catch (e){
       _txtTest.text = e.toString() ;
    } finally{
      if (response.statusCode == 200) {
        _txtTest.text = response.body;
        _success(response.body, true);
      } else {
         _txtTest.text = '失败:' + response.body;
      }
    }
  }

  _doGet() async {
    //叫号
    var url = Uri.parse(_url.text + "/getQueue/" + _setid.text);
    var response = await http.get(url);
    if (response.statusCode == 200) {
      _success(response.body, true);
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

  _success(String body, bool isNeedUtf8) {
    var map = jsonDecode(body);
    int total = map['data'].length;
    int i = 0;

    while (i < total) {
      var s = '请 ' +
          map['data'][i]["id"] +
          '[' +
          map['data'][i]["name"] +
          ']' +
          '到' +
          map['data'][i]["roomname"];
      _speak(s, 3);
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
    final url = await getUserConfig<String>('url',
        defaultValue: 'http://10.196.5.160');
    _url.text = url;
    final setid = await getUserConfig<String>('setid', defaultValue: '3');
    _setid.text = setid;
    final urljh = await getUserConfig<String>('urljh',
        defaultValue: 'http://10.196.5.143:8082');
    _urljh.text = urljh; 

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
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch $url';
    }
  }

  //叫号+排队显示
  Future<void> _speak1() async {
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
//'http://192.168.0.193:8082/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=3')

    openLink(
        _urljh.text  + '/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=' +
            _setid.text);

    // Navigator.push(
    //     context,
    //     //MaterialPageRoute(builder: (context) => WebviewWidget()),
    //     MaterialPageRoute(
    //         builder: (context) => BrowserPage(
    //             "http://192.168.0.193:8082/ris/?clz=com.bsoft.ris.exam.queuelist.queueview.QueueView&setid=3")));
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
    _speak("语音测试1，请PX008 [徐海生] 到8号诊室", 1);
    _speak("语音测试2，请PX009 '徐海生' 到8号诊室", 1);
    _speak("语音测试3，请PX010 /徐海生/ 到8号诊室", 1);
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
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 5.0, left: 10.0, right: 25.0),
      child: Column(children: [
        TextField(
          maxLines: 11,
          minLines: 1,
          controller: this._url,
          // onChanged: (String value) {
          //   _onChange(value);
          // },
        ),
        TextField(
          maxLines: 11,
          minLines: 1,
          controller: this._setid,
        ),
        TextField(
          maxLines: 11,
          minLines: 1,
          controller: this._urljh,
        ),
        TextField(
          maxLines: 11,
          minLines: 1,
          controller: this._txtTest,
        ),
      ]));

  Widget _btnSection() {
    return Container(
      padding: EdgeInsets.only(top: 50.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonColumn(
              Colors.green, Colors.greenAccent, Icons.save, '保存配置 ', _save),
          _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow,
              '排队显示', _speak1),
          _buildButtonColumn(Colors.green, Colors.greenAccent, Icons.play_arrow,
              '仅叫号', _speak2),
          _buildButtonColumn(
              Colors.red, Colors.redAccent, Icons.stop, '停止', _stop),
          _buildButtonColumn(
              Colors.blue, Colors.blueAccent, Icons.abc, '发声测试', _pause),
          _buildButtonColumn(
              Colors.blue, Colors.blueAccent, Icons.abc, 'GET测试', _doGetTest),
            
        ],
      ),
    );
  }

  Widget _enginesDropDownSection(List<dynamic> engines) => Container(
        padding: EdgeInsets.only(top: 50.0),
        child: DropdownButton(
          value: engine,
          items: getEnginesDropDownMenuItems(engines),
          onChanged: changedEnginesDropDownItem,
        ),
      );

  Widget _languageDropDownSection(List<dynamic> languages) => Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          value: language,
          items: getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
        ),
        Visibility(
          visible: isAndroid,
          child: Text("Is installed: $isCurrentLanguageInstalled"),
        ),
      ]));

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
    return Column(
      children: [_volume(), _pitch(), _rate()],
    );
  }

  Widget _volume() {
    return Slider(
        value: volume,
        onChanged: (newVolume) {
          setState(() => volume = newVolume);
        },
        min: 0.0,
        max: 1.0,
        divisions: 10,
        label: "Volume: $volume");
  }

  Widget _pitch() {
    return Slider(
      value: pitch,
      onChanged: (newPitch) {
        setState(() => pitch = newPitch);
      },
      min: 0.5,
      max: 2.0,
      divisions: 15,
      label: "Pitch: $pitch",
      activeColor: Colors.red,
    );
  }

  Widget _rate() {
    return Slider(
      value: rate,
      onChanged: (newRate) {
        setState(() => rate = newRate);
      },
      min: 0.0,
      max: 1.0,
      divisions: 10,
      label: "Rate: $rate",
      activeColor: Colors.green,
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
