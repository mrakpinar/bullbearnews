import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingViewChart extends StatefulWidget {
  final String symbol;
  final double height;
  final String theme;

  const TradingViewChart({
    super.key,
    required this.symbol,
    this.height = 450, // Yüksekliği artırdık
    this.theme = 'dark', // Tema seçeneği ekledik (dark/light)
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
    _initializeController();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>TradingView</title>
        <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
        <style>
          body { margin: 0; padding: 0; background: ${widget.theme == 'dark' ? '#1E222D' : '#fff'}; }
          #tradingview { height: 100vh; width: 100vw; }
        </style>
      </head>
      <body>
        <div id="tradingview"></div>
        <script type="text/javascript">
          new TradingView.widget({
            "autosize": true,
            "symbol": "BINANCE:${widget.symbol.toUpperCase()}USDT",
            "interval": "D",
            "timezone": "Etc/UTC",
            "theme": "${widget.theme}",
            "style": "1",
            "locale": "en",
            "toolbar_bg": "${widget.theme == 'dark' ? '#1E222D' : '#f1f3f6'}",
            "enable_publishing": false,
            "withdateranges": true,
            "hide_side_toolbar": false,
            "allow_symbol_change": true,
            "details": true,
            "hotlist": true,
            "calendar": true,

            "container_id": "tradingview",
            "show_popup_button": true,
            "popup_width": "1000",
            "popup_height": "650",
          });
        </script>
      </body>
      </html>
    ''';
  }
  // "studies": ["RSI@tv-basicstudies","MACD@tv-basicstudies"],

  void _toggleFullScreen() {
    setState(() {
      _isLoading = true;
      _isFullScreen = !_isFullScreen;
      _initializeController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isFullScreen ? _buildFullScreenChart() : _buildNormalChart();
  }

  Widget _buildNormalChart() {
    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color:
                widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _buildChartHeader(),
                Expanded(
                  child: WebViewWidget(controller: _controller),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildFullScreenChart() {
    return Scaffold(
      backgroundColor:
          widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
      appBar: AppBar(
        backgroundColor:
            widget.theme == 'dark' ? const Color(0xFF1E222D) : Colors.white,
        foregroundColor: widget.theme == 'dark' ? Colors.white : Colors.black,
        title: Text('${widget.symbol.toUpperCase()} Chart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: _toggleFullScreen,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildChartHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.symbol.toUpperCase()} Chart',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.theme == 'dark' ? Colors.white : Colors.black,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  widget.theme == 'dark' ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                  color: widget.theme == 'dark' ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  // Tema değişimi burada uygulanabilir
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                color: widget.theme == 'dark' ? Colors.white : Colors.black,
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
