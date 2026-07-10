import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'api_settings_screen.dart';

/// Profile — matches fish_feeder_extra_screens.html "Profile" checkpoint.
/// Account, my farms, system info, sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACCOUNT',
                style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
            Text('My profile',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('OK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        )),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GROUP21',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('farmer@pondA.ug',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                      SizedBox(height: 6),
                      StatusBadge(
                        label: 'Farm operator',
                        color: AppColors.primary,
                        bgColor: Color(0xFFDCFCE7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // My farms
          const SectionHeader(label: 'My farms'),
          const SizedBox(height: 8),
          const AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _FarmRow(
                    name: 'Pond A · Feeder #001',
                    status: 'Online',
                    color: AppColors.online),
                Divider(height: 1),
                _FarmRow(
                    name: 'Pond B · Feeder #002',
                    status: 'Offline',
                    color: AppColors.offline),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Account
          const SectionHeader(label: 'Account'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const _NavRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailingStatus: 'On',
                    color: AppColors.online),
                const Divider(height: 1),
                const _NavRow(
                    icon: Icons.lock_outline,
                    label: 'Change password',
                    chevron: true),
                const Divider(height: 1),
                const _NavRow(
                    icon: Icons.person_add_outlined,
                    label: 'Invite team member',
                    chevron: true),
                const Divider(height: 1),
                _NavRow(
                    icon: Icons.dns_outlined,
                    label: 'Database connection',
                    chevron: true,
                    onTap: () => Navigator.pushNamed(context, '/db-settings')),
                const Divider(height: 1),
                _NavRow(
                    icon: Icons.settings_outlined,
                    label: 'API settings',
                    chevron: true,
                    onTap: () => Navigator.pushNamed(context, '/api-settings')),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // System
          const SectionHeader(label: 'System'),
          const SizedBox(height: 8),
          const AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SystemRow(
                    label: 'Backend',
                    value: 'Render · online',
                    color: AppColors.online),
                Divider(height: 1),
                _SystemRow(
                    label: 'Database',
                    value: 'Neon PostgreSQL',
                    color: AppColors.textMedium),
                Divider(height: 1),
                _SystemRow(
                    label: 'App version',
                    value: 'v1.0.0',
                    color: AppColors.textMedium),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Sign out button (red outline)
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text(
                      'You will need to log in again to control your feeders.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (_) => false);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.offline),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: AppColors.offline,
              side: const BorderSide(color: AppColors.offline, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const StatusBadge(
      {super.key,
      required this.label,
      required this.color,
      required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class _FarmRow extends StatelessWidget {
  final String name;
  final String status;
  final Color color;
  const _FarmRow(
      {required this.name, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          StatusBadge(
              label: status,
              color: color,
              bgColor: color.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool chevron;
  final String? trailingStatus;
  final Color? color;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    this.chevron = false,
    this.trailingStatus,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMedium),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ),
            if (trailingStatus != null)
              StatusBadge(
                  label: trailingStatus!,
                  color: color ?? AppColors.online,
                  bgColor: const Color(0xFFDCFCE7))
            else if (chevron)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _SystemRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SystemRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark)),
          Text(value,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
