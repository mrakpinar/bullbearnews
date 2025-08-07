import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;
  const SwipeToReplyWrapper({super.key, required this.child, this.onReply});

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  double _dragExtent = 0;
  bool _dragUnderway = false;
  static const double _maxDragDistance = 80.0;
  static const double _triggerDistance = 50.0; // Trigger için gerekli mesafe

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.onReply == null) return;
    _dragUnderway = true;
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.onReply == null || !_dragUnderway) return;

    final delta = details.primaryDelta ?? 0;

    // Sadece sağa sürüklendiğinde çalışsın (pozitif delta)
    if (delta > 0) {
      setState(() {
        _dragExtent = (_dragExtent + delta).clamp(0.0, _maxDragDistance);
      });

      // Animation controller değerini güncelle
      _animationController.value =
          (_dragExtent / _maxDragDistance).clamp(0.0, 1.0);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.onReply == null || !_dragUnderway) return;

    _dragUnderway = false;

    // Trigger mesafesine ulaştıysa reply fonksiyonunu çağır
    if (_dragExtent >= _triggerDistance) {
      widget.onReply!();

      // Haptic feedback ekle
      HapticFeedback.lightImpact();
    }

    // Animation'u sıfırla
    _animationController.animateTo(0).then((_) {
      if (mounted) {
        setState(() {
          _dragExtent = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null) {
      return widget.child;
    }

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Reply icon background
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                // Fade animation'u drag extent'e göre ayarla
                final opacity =
                    (_dragExtent / _maxDragDistance).clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.reply,
                        size: 20,
                        color: _dragExtent >= _triggerDistance
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Message content
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
