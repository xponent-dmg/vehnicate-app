import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapWebviewScreen extends StatefulWidget {
  const MapWebviewScreen({super.key});

  @override
  State<MapWebviewScreen> createState() => _MapWebviewScreenState();
}

class _MapWebviewScreenState extends State<MapWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                _controller.runJavaScript(
                  "var footer = document.querySelector('footer'); if (footer) footer.style.display = 'none';",
                );
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                // Keep navigation inside the WebView
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse('https://vehnicate-maps.vercel.app/map'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            // Custom back button to handle both webview history and flutter navigation
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () async {
                  if (await _controller.canGoBack()) {
                    _controller.goBack();
                  } else {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
