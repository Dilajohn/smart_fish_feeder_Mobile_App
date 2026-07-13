import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── Bottom Navigation Bar ─────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_outlined),
            selectedIcon: Icon(Icons.water_rounded),
            label: 'Ponds',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Refill',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory_rounded),
            label: 'Device',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String label;
  final String? title;
  final Widget? action;
  const SectionHeader({super.key, required this.label, this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTextStyles.screenLabel),
              if (title != null) ...[
                const SizedBox(height: 2),
                Text(title!, style: AppTextStyles.screenTitle),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const StatusBadge({super.key, required this.label, required this.color, required this.bgColor});

  factory StatusBadge.online() => const StatusBadge(
      label: 'Online', color: AppColors.online, bgColor: Color(0xFFDCFCE7));
  factory StatusBadge.offline() => const StatusBadge(
      label: 'Offline', color: AppColors.offline, bgColor: Color(0xFFFEE2E2));
  factory StatusBadge.warning(String label) =>
      StatusBadge(label: label, color: AppColors.warning, bgColor: const Color(0xFFFEF3C7));
  factory StatusBadge.success([String label = 'Success']) =>
      StatusBadge(label: label, color: AppColors.online, bgColor: const Color(0xFFDCFCE7));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────
class AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const AlertBanner(
      {super.key,
      required this.message,
      required this.color,
      required this.bgColor,
      required this.icon});

  factory AlertBanner.warning(String msg) => AlertBanner(
      message: msg,
      color: AppColors.warning,
      bgColor: const Color(0xFFFFFBEB),
      icon: Icons.warning_amber_rounded);
  factory AlertBanner.success(String msg) => AlertBanner(
      message: msg,
      color: AppColors.online,
      bgColor: const Color(0xFFF0FDF4),
      icon: Icons.check_circle_outline_rounded);
  factory AlertBanner.info(String msg) => AlertBanner(
      message: msg,
      color: AppColors.info,
      bgColor: const Color(0xFFEFF6FF),
      icon: Icons.info_outline_rounded);
  factory AlertBanner.error(String msg) => AlertBanner(
      message: msg,
      color: AppColors.offline,
      bgColor: const Color(0xFFFFF1F1),
      icon: Icons.error_outline_rounded);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4))),
        ],
      ),
    );
  }
}

// ── App Card ──────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Gradient Card ─────────────────────────────────────────────
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const GradientCard(
      {super.key, required this.child, required this.colors, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Stat Tile ─────────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? bgColor;
  const StatTile(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bgColor ?? color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.4)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontSize: 10, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  const InfoRow({super.key, required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          trailing ??
              Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// ── Tech Chip ─────────────────────────────────────────────────
class TechChip extends StatelessWidget {
  final String label;
  final Color? color;
  const TechChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        border: Border.all(color: c.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: c, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

// ── Screen App Bar ────────────────────────────────────────────
class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String label;
  final String title;
  final List<Widget>? actions;
  const ScreenAppBar(
      {super.key, required this.label, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.screenLabel),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark)),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ── Pill Button ───────────────────────────────────────────────
class PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PillButton(
      {super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceGreen,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.textWhite : AppColors.textMedium,
          ),
        ),
      ),
    );
  }
}
