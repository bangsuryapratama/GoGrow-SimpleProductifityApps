import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─── Section Label ────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    child: Text(text.toUpperCase(), style: AppTheme.labelSmall),
  );
}

// ─── Surface Card ─────────────────────────────────────────────────────────────
class SurfaceCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final bool glowing;
  final Color? glowColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppTheme.radiusL,
    this.color,
    this.onTap,
    this.glowing = false,
    this.glowColor,
  });

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? AppTheme.accent;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color ?? AppTheme.surface,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: widget.glowing
                ? AppTheme.glowShadow(glow, blur: 24)
                : AppTheme.cardShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Glass Card ───────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppTheme.radiusL,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final double? width;
  final LinearGradient? gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.width,
    this.gradient,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.onTap != null && !widget.loading ? (_) => _controller.forward() : null,
    onTapUp: widget.onTap != null && !widget.loading ? (_) { _controller.reverse(); widget.onTap!(); } : null,
    onTapCancel: () => _controller.reverse(),
    child: AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
      child: Container(
        width: widget.width ?? double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: widget.gradient ?? AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.glowShadow(AppTheme.accent, blur: 16),
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: Colors.black),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
        ),
      ),
    ),
  );
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.message, this.subtitle});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + (_controller.value * 0.08),
              child: Opacity(
                opacity: 0.4 + (_controller.value * 0.3),
                child: Icon(widget.icon, size: 52, color: AppTheme.accent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.message, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(widget.subtitle!, style: AppTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

// ─── Loading State ────────────────────────────────────────────────────────────
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
  );
}

// ─── Dismiss Background ───────────────────────────────────────────────────────
class DismissBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Alignment alignment;

  const DismissBackground({
    super.key,
    this.color = AppTheme.danger,
    this.icon = Icons.delete_outline,
    this.alignment = Alignment.centerRight,
  });

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.danger.withOpacity(0.8), AppTheme.danger.withOpacity(0.5)],
        begin: alignment == Alignment.centerRight ? Alignment.centerRight : Alignment.centerLeft,
        end: alignment == Alignment.centerRight ? Alignment.centerLeft : Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
    ),
    child: Icon(icon, color: Colors.white),
  );
}

// ─── XP Badge ─────────────────────────────────────────────────────────────────
class XpBadge extends StatelessWidget {
  final int xp;
  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      gradient: AppTheme.accentGradient,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      boxShadow: AppTheme.glowShadow(AppTheme.accent, blur: 10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt, color: Colors.black, size: 15),
        const SizedBox(width: 4),
        Text('$xp XP', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    ),
  );
}

// ─── Accent Chip ──────────────────────────────────────────────────────────────
class AccentChip extends StatelessWidget {
  final String label;
  final Color color;

  const AccentChip({super.key, required this.label, this.color = AppTheme.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

// ─── Animated Progress Ring ───────────────────────────────────────────────────
class AnimatedProgressRing extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final LinearGradient? gradient;
  final Widget? center;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 8,
    this.gradient,
    this.center,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _oldProgress = old.progress;
      _progressAnim = Tween<double>(begin: _oldProgress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(
          progress: _progressAnim.value,
          strokeWidth: widget.strokeWidth,
          gradient: widget.gradient ?? AppTheme.accentGradient,
        ),
        child: widget.center != null
            ? Center(child: widget.center)
            : null,
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final LinearGradient gradient;

  _RingPainter({required this.progress, required this.strokeWidth, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..color = AppTheme.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round);

    if (progress <= 0) return;

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5708; // -π/2 (top)
    final sweepAngle = 2 * 3.14159 * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Shimmer Loading ──────────────────────────────────────────────────────────
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.radius = AppTheme.radiusM,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: const [
            Color(0xFF111318),
            Color(0xFF1E232C),
            Color(0xFF111318),
          ],
        ),
      ),
    ),
  );
}

// ─── Network Image with Fallback ──────────────────────────────────────────────
class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const NetImage(this.url, {
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.zero,
    child: url.isNotEmpty
        ? Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _placeholder(),
            loadingBuilder: (_, child, progress) =>
              progress == null ? child : ShimmerLoading(width: width ?? 100, height: height ?? 100, radius: 0),
          )
        : _placeholder(),
  );

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppTheme.surfaceAlt,
    child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textMuted),
  );
}