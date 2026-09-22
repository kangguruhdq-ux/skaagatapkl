import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';

class MobilePreviewFrame extends StatefulWidget {
  final Widget child;

  const MobilePreviewFrame({super.key, required this.child});

  @override
  State<MobilePreviewFrame> createState() => _MobilePreviewFrameState();
}

class _MobilePreviewFrameState extends State<MobilePreviewFrame> {
  bool _forceFullscreen = false;
  late Timer _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat('HH:mm').format(now);
    if (mounted && formatted != _currentTime) {
      setState(() {
        _currentTime = formatted;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not running on web or if screen width is narrow (mobile screen), or user forced fullscreen:
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (!kIsWeb || screenWidth <= 640 || _forceFullscreen) {
      return widget.child;
    }

    // Desktop Browser Mobile Preview Frame
    const phoneWidth = 412.0;
    final phoneHeight = (screenHeight * 0.94).clamp(740.0, 890.0);

    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient gradient and grid
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF0F1E36),
                    Color(0xFF070D18),
                  ],
                ),
              ),
            ),
          ),

          // Subtle Decorative Branding in Background
          Positioned(
            top: 24,
            left: 32,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('3',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SKAGATA PKL INTELLIGENCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'SMKN 3 Yogyakarta • Mobile Preview Shell',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Control Toolbar (Top Right)
          Positioned(
            top: 24,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_android,
                      color: AppColors.secondary, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Preview Mobile: 412 × 860',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _forceFullscreen = !_forceFullscreen;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.fullscreen, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Layar Penuh',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Centered Mobile Device Phone Mockup
          Center(
            child: Container(
              width: phoneWidth,
              height: phoneHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                border: Border.all(
                  color: const Color(0xFF26334D),
                  width: 10,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    spreadRadius: 4,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Container(
                  color: AppColors.surface,
                  child: Stack(
                    children: [
                      // Child Application Screen
                      Positioned.fill(
                        top: 28, // Leave room for top simulated status bar
                        child: widget.child,
                      ),

                      // Simulated Phone Status Bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 28,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color:
                              AppColors.surfaceLowest.withValues(alpha: 0.95),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currentTime.isEmpty ? '07:30' : _currentTime,
                                style: TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Dynamic Island / Camera Punch-hole
                              Container(
                                width: 70,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.signal_cellular_alt,
                                      size: 12, color: AppColors.onSurface),
                                  const SizedBox(width: 4),
                                  Icon(Icons.wifi,
                                      size: 12, color: AppColors.onSurface),
                                  const SizedBox(width: 4),
                                  Icon(Icons.battery_5_bar,
                                      size: 14, color: AppColors.onSurface),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
