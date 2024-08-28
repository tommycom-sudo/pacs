import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';

/// App内部Web浏览器页面
class BrowserPage extends StatefulWidget {
  const BrowserPage(this.url, {Key? key}) : super(key: key);

  final String url;

  @override
  State createState() => _BrowserPageState();
}

/// 生成进度条组件，进度从0 ~ 1
_createProgressBar(double progress, BuildContext context) {
  return LinearProgressIndicator(
    backgroundColor: Colors.white70.withOpacity(0),
    value: progress == 1.0 ? 0 : progress,
    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
  );
}

class _BrowserPageState extends State<BrowserPage> {
  InAppWebViewController? _webViewController;
  String? _webTitle;
  double _progress = 0;
  bool isCanGoBack = false;
  bool isCanForward = false;

  final InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),

    /// android 支持HybridComposition
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  Future<String?> getUrl() {
    if (_webViewController == null) {
      return Future.sync(() => null);
    }
    return _webViewController!.getUrl().then((uri) => uri.toString());
  }

  Future<void> loadUrl(String url) {
    if (_webViewController == null) {
      return Future.sync(() => null);
    }
    return _webViewController!
        .loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          Future<bool> canGoBack = _webViewController!.canGoBack();
          return canGoBack.then((isCanGoBack) {
            if (isCanGoBack) {
              _webViewController!.goBack();
              return false;
            } else {
              return true;
            }
          });
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Row(
              children: [
                isCanGoBack
                    ? IconButton(
                        onPressed: () {
                          _webViewController?.goBack();
                        },
                        icon: const Icon(Icons.arrow_back))
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          SystemNavigator.pop();
                        })
              ],
            ),
            title: Text(_webTitle ?? "FlutterWebView"),
          ),
          body: Column(
            children: [
              Expanded(
                  child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialOptions: options,
                    onWebViewCreated: (InAppWebViewController controller) {
                      _webViewController = controller;
                    },
                    onTitleChanged:
                        (InAppWebViewController controller, String? title) {
                      setState(() {
                        _webTitle = title ?? "";
                      });
                    },
                    onLoadStop: (InAppWebViewController controller, Uri? url) {
                      //页面加载完毕，显示隐藏AppBar的返回键
                      controller.canGoBack().then((canGoBack) => {
                            setState(() {
                              isCanGoBack = canGoBack;
                            })
                          });
                      controller.canGoForward().then((canForward) => {
                            setState(() {
                              isCanForward = canForward;
                            })
                          });
                    },
                    onProgressChanged:
                        (InAppWebViewController controller, int progress) {
                      //进度从0 ~ 100
                      setState(() {
                        _progress = progress / 100.0;
                      });
                    },
                  ),
                  _createProgressBar(_progress, context)
                ],
              ))
            ],
          ),
        ));
  }
}
