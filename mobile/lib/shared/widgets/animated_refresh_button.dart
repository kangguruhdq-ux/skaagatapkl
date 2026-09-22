import 'package:flutter/material.dart';

class AnimatedRefreshButton extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Color color;
  final double size;
  final String tooltip;

  const AnimatedRefreshButton({
    Key? key,
    required this.onRefresh,
    this.color = Colors.white,
    this.size = 20.0,
    this.tooltip = 'Segarkan Data',
  }) : super(key: key);

  @override
  State<AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _controller.repeat();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      icon: RotationTransition(
        turns: _controller,
        child: Icon(Icons.refresh, color: widget.color, size: widget.size),
      ),
      onPressed: _isRefreshing ? null : _handlePress,
    );
  }
}
