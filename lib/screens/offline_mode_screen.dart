import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

/// Offline mode screen — matches fish_feeder_extra_screens.html "Offline mode"
/// Shows: RTC fallback active, buffered events, next scheduled feed.
class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingEvents = const [
      _PendingEvent(time: '12:00 PM', portion: 'Large', grams: 22),
      _PendingEvent(time: '5:00 PM', portion: 'Small', grams: 8),
      _PendingEvent(time: '7:00 AM', portion: 'Medium', grams: 15),
    ];

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF374151),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('FEEDER #001 · POND A',
                style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            Text('Offline mode',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big error alert
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.wifi_off_rounded, color: AppColors.offline, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Device lost WiFi at 11:14 PM. Running on local RTC schedule. Data will sync when reconnected.',
                      style: TextStyle(
                        color: AppColors.offline,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const SectionHeader(label: 'RTC status'),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  _RtcRow(label: 'RTC clock', value: 'Running', color: AppColors.online),
                  Divider(height: 1),
                  _RtcRow(label: 'Schedule loaded', value: 'Yes', color: AppColors.online),
                  Divider(height: 1),
                  _RtcRow(label: 'EEPROM backup', value: 'Saved', color: AppColors.online),
                  Divider(height: 1),
                  _RtcRow(label: 'Last sync', value: 'Yesterday 6:00 PM', isPlain: true),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const SectionHeader(label: 'Buffered events (unsent)'),
            const SizedBox(height: 8),
            ...pendingEvents.map((e) => _PendingEventTile(event: e)),

            const SizedBox(height: 18),

            const SectionHeader(label: 'Next scheduled feed'),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  _RtcRow(label: 'Time', value: '12:00 PM today', isPlain: true),
                  Divider(height: 1),
                  _RtcRow(label: 'Portion', value: 'Large · 22g', isPlain: true),
                  Divider(height: 1),
                  _RtcRow(label: 'Source', value: 'RTC local', color: AppColors.info),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attempting to reconnect…'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry connection'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RtcRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isPlain;

  const _RtcRow({
    required this.label,
    required this.value,
    this.color,
    this.isPlain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
          if (isPlain)
            Text(value,
                style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w700))
          else
            StatusBadge(
              label: value,
              color: color ?? AppColors.online,
              bgColor: const Color(0xFFDCFCE7),
            ),
        ],
      ),
    );
  }
}

class _PendingEvent {
  final String time;
  final String portion;
  final int grams;
  const _PendingEvent({required this.time, required this.portion, required this.grams});
}

class _PendingEventTile extends StatelessWidget {
  final _PendingEvent event;
  const _PendingEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.time} — ${event.portion}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('${event.grams}g · RTC triggered',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}