import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── Bottom Navigation Bar ──────────────────────────────────
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: Colors.white,
      elevation: 0,
<<<<<<< HEAD
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
=======
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
>>>>>>> main
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.water_outlined),
          selectedIcon: Icon(Icons.water, color: AppColors.primary),
          label: 'Ponds',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          selectedIcon: Icon(Icons.show_chart, color: AppColors.primary),
          label: 'Refill',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: AppColors.primary),
          label: 'Device',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
          label: 'More',
        ),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String label;
  final String? title;

  const SectionHeader({super.key, required this.label, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.screenLabel),
        if (title != null) ...[
          const SizedBox(height: 2),
          Text(title!, style: AppTextStyles.screenTitle),
        ]
      ],
    );
  }
}

// ── Status Badge ───────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  factory StatusBadge.online() => const StatusBadge(
      label: 'Online', color: AppColors.online, bgColor: Color(0xFFDCFCE7));

  factory StatusBadge.offline() => const StatusBadge(
      label: 'Offline', color: AppColors.offline, bgColor: Color(0xFFFEE2E2));

  factory StatusBadge.warning(String label) => StatusBadge(
      label: label, color: AppColors.warning, bgColor: const Color(0xFFFEF9C3));

<<<<<<< HEAD
=======
  factory StatusBadge.success([String label = 'Success']) => StatusBadge(
      label: label, color: AppColors.online, bgColor: const Color(0xFFDCFCE7));

>>>>>>> main
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Info Alert Banner ──────────────────────────────────────
class AlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const AlertBanner({
    super.key,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  factory AlertBanner.warning(String message) => AlertBanner(
        message: message,
        color: AppColors.warning,
        bgColor: const Color(0xFFFFFBEB),
        icon: Icons.warning_amber_rounded,
      );

  factory AlertBanner.success(String message) => AlertBanner(
        message: message,
        color: AppColors.online,
        bgColor: const Color(0xFFF0FDF4),
        icon: Icons.check_circle_outline,
      );

  factory AlertBanner.info(String message) => AlertBanner(
        message: message,
        color: AppColors.info,
        bgColor: const Color(0xFFEFF6FF),
        icon: Icons.info_outline,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
        border: Border.all(color: color.withValues(alpha: 0.3)),
=======
        border: Border.all(color: color.withValues(alpha: 0.3)),
>>>>>>> main
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Card wrapper ───────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ── Tech Chip ─────────────────────────────────────────────
class TechChip extends StatelessWidget {
  final String label;

  const TechChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
<<<<<<< HEAD
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
=======
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
>>>>>>> main
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Row key-value pair ─────────────────────────────────────
<<<<<<< HEAD
class DataRow extends StatelessWidget {
  const DataRow({super.key});

=======
class InfoRow extends StatelessWidget {
>>>>>>> main
  final String label;
  final String value;
  final Widget? trailing;

<<<<<<< HEAD
  const DataRow({
=======
  const InfoRow({
>>>>>>> main
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          trailing ??
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
        ],
      ),
    );
  }
}
