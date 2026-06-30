import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Notifications — matches fish_feeder_extra_screens.html "Notifications" checkpoint.
/// "Today" and "Yesterday" sections, color-coded alert items.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = const [
      _AlertItem(
        color: AppColors.offline,
        title: 'Food level critical',
        subtitle: 'Hopper at 18% — ~2 days left',
        meta: '2 min ago · Pond A',
      ),
      _AlertItem(
        color: AppColors.online,
        title: 'Feed completed',
        subtitle: '7:00 AM scheduled · 15g confirmed',
        meta: '2 hrs ago · Pond A',
      ),
      _AlertItem(
        color: AppColors.warning,
        title: 'Device back online',
        subtitle: '2 offline events synced',
        meta: '5 hrs ago · Pond A',
      ),
    ];

    final yesterday = const [
      _AlertItem(
        color: AppColors.offline,
        title: 'Device went offline',
        subtitle: 'WiFi lost · RTC fallback active',
        meta: '11:14 PM',
      ),
      _AlertItem(
        color: Color(0xFF7C3AED),
        title: 'Power restored',
        subtitle: 'Schedule reloaded from EEPROM',
        meta: '2:02 PM',
      ),
      _AlertItem(
        color: AppColors.online,
        title: 'Schedule synced',
        subtitle: '3 changes pushed to device',
        meta: '4:30 PM',
      ),
      _AlertItem(
        color: AppColors.offline,
        title: 'pH alert — Pond B',
        subtitle: 'pH at 5.8 · feeding paused',
        meta: '9:38 AM',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('ALERTS & UPDATES',
                style: TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            Text('Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: StatusBadge(
                label: '4 unread',
                color: AppColors.offline,
                bgColor: Color(0xFFFEE2E2),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionLabel('Today'),
          ...today.map((a) => _AlertTile(item: a)),
          const _SectionLabel('Yesterday'),
          ...yesterday.map((a) => _AlertTile(item: a)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          )),
    );
  }
}

class _AlertItem {
  final Color color;
  final String title;
  final String subtitle;
  final String meta;
  const _AlertItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.meta,
  });
}

class _AlertTile extends StatelessWidget {
  final _AlertItem item;
  const _AlertTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text(item.subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium, height: 1.4)),
                const SizedBox(height: 4),
                Text(item.meta,
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const StatusBadge({super.key, required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}