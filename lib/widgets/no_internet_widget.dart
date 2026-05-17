import 'package:flutter/material.dart';

class NoInternetWidget extends StatefulWidget {
  const NoInternetWidget({
    super.key,
    required this.onRetry,
    this.onExit,
    this.isRetrying = false,
  });

  final VoidCallback onRetry;
  final VoidCallback? onExit;
  final bool isRetrying;

  @override
  State<NoInternetWidget> createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  color: const Color(0xFF151A22),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0x338FE3CF)),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFF8FE3CF),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'No Internet Connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB8C1D1),
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: widget.isRetrying ? null : widget.onRetry,
              icon: widget.isRetrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
            if (widget.onExit != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.isRetrying ? null : widget.onExit,
                child: const Text('Exit App'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
