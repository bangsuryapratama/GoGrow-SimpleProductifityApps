import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─── Section Label ──────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
    child: Text(text.toUpperCase(), style: AppTheme.labelSmall),
  );
}

// ─── Surface Card ───────────────────────────────────────────────────────────────
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppTheme.radiusL,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: child,
    ),
  );
}

// ─── Primary Button ─────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width ?? double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
      onPressed: loading ? null : onTap,
      child: loading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
    ),
  );
}

// ─── Empty State ────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.textDisabled),
          const SizedBox(height: 16),
          Text(message, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

// ─── Loading State ──────────────────────────────────────────────────────────────
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      color: AppTheme.accent,
      strokeWidth: 2,
    ),
  );
}

// ─── Dismiss Background ─────────────────────────────────────────────────────────
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
      color: color.withOpacity(0.85),
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
    ),
    child: Icon(icon, color: Colors.white),
  );
}

// ─── XP Badge ───────────────────────────────────────────────────────────────────
class XpBadge extends StatelessWidget {
  final int xp;
  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt, color: AppTheme.accent, size: 16),
        const SizedBox(width: 4),
        Text(
          '$xp XP',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

// ─── Accent Chip ────────────────────────────────────────────────────────────────
class AccentChip extends StatelessWidget {
  final String label;
  final Color color;

  const AccentChip({super.key, required this.label, this.color = AppTheme.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

// ─── Network Image with Fallback ─────────────────────────────────────────────────
class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const NetImage(
    this.url, {
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
              progress == null ? child : _placeholder(),
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