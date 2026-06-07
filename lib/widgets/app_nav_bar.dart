import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfessionalNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ProfessionalNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.adjust_outlined, activeIcon: Icons.adjust_rounded, label: "Focus", index: 0, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.repeat_outlined, activeIcon: Icons.repeat_on, label: "Habit", index: 1, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: "GrowMind", index: 2, currentIndex: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: "Profil", index: 3, currentIndex: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex && widget.currentIndex == widget.index) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.currentIndex == widget.index;

    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: isSelected ? _scaleAnim.value : 1.0,
          child: child,
        ),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentDim : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? AppTheme.glowShadow(AppTheme.accent, blur: 12) : null,
                ),
                child: Icon(
                  isSelected ? widget.activeIcon : widget.icon,
                  color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: isSelected ? 18 : 0,
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.accentGradient : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}