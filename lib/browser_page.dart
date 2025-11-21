import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _webViewController;
  String? _webTitle;
  double _progress = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('BrowserPage initState - URL: ${widget.url}');
    _initializeWebView();
  }

  void _initializeWebView() {
    debugPrint('=== 开始初始化WebView ===');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView progress: $progress%');
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            debugPrint('WebView started loading: $url');
            setState(() {
              isLoading = true;
              _progress = 0;
            });
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished loading: $url');
            setState(() {
              isLoading = false;
              _progress = 1.0;
            });

            // 获取页面标题
            _webViewController.getTitle().then((title) {
              setState(() {
                _webTitle = title ?? "WebView";
              });
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('WebView navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    debugPrint('=== WebView初始化完成 ===');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          await _webViewController.goBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        // 完全全屏WebView，移除所有浮动按钮
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              _createProgressBar(_progress, context),
            ],
          ),
        ),
      ),
    );
  }
}