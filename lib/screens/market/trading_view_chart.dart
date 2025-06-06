import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewChart extends StatefulWidget {
  final String symbol;
  final double height;
  final String theme;

  const TradingViewChart({
    super.key,
    required this.symbol,
    this.height = 350, // Yüksekliği artırdık
    this.theme = 'dark',
  });

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
        widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
              // Grafik yüklendikten sonra boyutlandırmayı yeniden ayarla
              _controller.runJavaScript('''
                setTimeout(function() {
                  if (window.tvWidget) {
                    window.tvWidget.resize();
                  }
                }, 1000);
              ''');
            }
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    final symbol = widget.symbol.toUpperCase();
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <title>TradingView Chart</title>
        <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          html, body {
            height: 100%;
            width: 100%;
            background: ${widget.theme == 'dark' ? '#1E222D' : '#ffffff'};
            overflow: hidden;
          }
          #tradingview_container {
            height: 100vh;
            width: 100vw;
            position: relative;
          }
          #tradingview {
            height: 100%;
            width: 100%;
          }
        </style>
      </head>
      <body>
        <div id="tradingview_container">
          <div id="tradingview"></div>
        </div>
        <script>
          window.tvWidget = new TradingView.widget({
            "width": "100%",
            "height": "100%",
            "symbol": "BINANCE:${symbol}USDT",
            "interval": "D",
            "timezone": "Etc/UTC",
            "theme": "${widget.theme}",
            "style": "1",
            "locale": "en",
            "toolbar_bg": "${widget.theme == 'dark' ? '#1E222D' : '#f1f3f6'}",
            "enable_publishing": false,
            "allow_symbol_change": false,
            "container_id": "tradingview",
            "autosize": true,
            "hide_top_toolbar": false,
            "hide_legend": false,
            "save_image": false,
            "hide_volume": false,
            "support_host": "https://www.tradingview.com"
          });
          
          // Pencere boyutu değiştiğinde grafik boyutunu ayarla
          window.addEventListener('resize', function() {
            if (window.tvWidget) {
              window.tvWidget.resize();
            }
          });
          
          // Grafik yüklendiğinde boyutu ayarla
          window.addEventListener('load', function() {
            setTimeout(function() {
              if (window.tvWidget) {
                window.tvWidget.resize();
              }
            }, 500);
          });
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return _isFullScreen ? _buildFullScreenChart() : _buildNormalChart();
  }

  Widget _buildNormalChart() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              Container(
                color: widget.theme == 'dark'
                    ? const Color(0xFF1E222D)
                    : Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            // Tam ekran butonu
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isFullScreen = true),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenChart() {
    return Scaffold(
      backgroundColor:
          widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
      appBar: AppBar(
        title: Text('${widget.symbol.toUpperCase()} Chart'),
        backgroundColor:
            widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
        foregroundColor: widget.theme == 'dark' ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: () => setState(() => _isFullScreen = false),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              color: widget.theme == 'dark'
                  ? const Color(0xFF1E222D)
                  : Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
