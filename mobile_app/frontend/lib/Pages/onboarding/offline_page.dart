import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opsin/core/constants/app_gradients.dart';

/// Full-screen page shown when the device has no internet connection.
///
/// Pass an [onRetry] callback so the caller can re-check connectivity.
class OfflinePage extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflinePage({super.key, this.onRetry});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage>
    with TickerProviderStateMixin {
  // ── Pulse animation for the icon ────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // ── Subtle floating animation for the card ──────────────────────────────────
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  // ── Fade-in for everything ──────────────────────────────────────────────────
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // ── Retrying state ──────────────────────────────────────────────────────────
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    // Pulse: icon scales between 0.92 and 1.08 continuously
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Float: card moves up/down by 8px continuously
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Fade in on load
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    // Give the caller at least 1.2 s so the spinner is visible
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1200)),
      Future<void>.microtask(() => widget.onRetry?.call()),
    ]);
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.mainBackground),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Floating icon card ──────────────────────────────────
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder:
                          (context, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          ),
                      child: _IconCard(pulseAnim: _pulseAnim),
                    ),

                    const SizedBox(height: 40),

                    // ── Title ───────────────────────────────────────────────
                    const Text(
                      'You\'re offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // ── Subtitle ────────────────────────────────────────────
                    const Text(
                      'No internet connection detected.\nCheck your Wi-Fi or mobile data and try again.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // ── Retry button ────────────────────────────────────────
                    _RetryButton(isRetrying: _isRetrying, onTap: _handleRetry),

                    const SizedBox(height: 60),

                    // ── Footer branding ─────────────────────────────────────
                    Text(
                      'vehnicate@2025',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.18),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Icon card ────────────────────────────────────────────────────────────────

class _IconCard extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _IconCard({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: ScaleTransition(
          scale: pulseAnim,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                ),
              ),
              // Icon
              const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: AppColors.lightPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Retry button ─────────────────────────────────────────────────────────────

class _RetryButton extends StatelessWidget {
  final bool isRetrying;
  final VoidCallback onTap;

  const _RetryButton({required this.isRetrying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isRetrying ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient:
              isRetrying
                  ? null
                  : AppGradients.primaryGradient,
          color: isRetrying ? AppColors.background : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRetrying ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
          boxShadow:
              isRetrying
                  ? []
                  : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        child: Center(
          child:
              isRetrying
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                  : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Try again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
