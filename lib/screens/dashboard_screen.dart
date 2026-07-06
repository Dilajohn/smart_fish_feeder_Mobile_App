import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final todaySchedules =
        state.schedules.where((s) => s.pondName == 'Pond A').toList();

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      body: CustomScrollView(
        slivers: [
          // App bar with greeting
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('FEEDER #001 · POND A',
                            style: AppTextStyles.screenLabel),
                        SizedBox(height: 2),
                        Text('Feeder Dashboard',
                            style: AppTextStyles.screenTitle),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                              radius: 4, backgroundColor: AppColors.online),
                          SizedBox(width: 6),
                          Text('Online',
                              style: TextStyle(
                                  color: AppColors.online,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alerts
                if (state.hasCriticalFood)
                  AlertBanner.warning(
                      '⚠ Pond C hopper is critically low (19%). Refill soon.'),
                if (state.hasOfflinePond)
                  AlertBanner.warning(
                      'Pond B feeder is offline. Last ping: 8h ago.'),

                const SizedBox(height: 8),

                // Quick stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      _StatCard(
                          label: 'Feeds Today',
                          value: '2',
                          icon: Icons.restaurant_outlined,
                          color: AppColors.primary),
                      SizedBox(width: 12),
                      _StatCard(
                          label: 'Food Level',
                          value: '67%',
                          icon: Icons.water_drop_outlined,
                          color: AppColors.info),
                      SizedBox(width: 12),
                      _StatCard(
                          label: 'Temp',
                          value: '24°C',
                          icon: Icons.thermostat_outlined,
                          color: AppColors.warning),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Manual feed trigger card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ManualFeedCard(),
                ),

                const SizedBox(height: 20),

                // Today's schedules
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionHeader(
                          label: 'Today', title: 'Feed Schedules'),
                      TextButton(
                        onPressed: () {},
                        child: const Text('+ Add',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      )
                    ],
                  ),
                ),

                ...todaySchedules.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      child: _ScheduleCard(schedule: s),
                    )),

                const SizedBox(height: 20),

                // Recent feed logs
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                      label: 'History', title: 'Recent Feed Events'),
                ),
                const SizedBox(height: 10),
                ...state.feedLogs.take(4).map((log) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: _FeedLogTile(log: log),
                    )),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ManualFeedCard extends StatefulWidget {
  @override
  State<_ManualFeedCard> createState() => _ManualFeedCardState();
}

class _ManualFeedCardState extends State<_ManualFeedCard> {
  bool _feeding = false;
  bool _fed = false;

  void _triggerFeed() async {
    setState(() {
      _feeding = true;
      _fed = false;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _feeding = false;
        _fed = true;
      });
    }
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _fed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              const Text('MANUAL TRIGGER',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const Spacer(),
              if (_fed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('✓ Fed!',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Feed Now',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Servo runs for 8 seconds · ~120g portion',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_feeding || _fed) ? null : _triggerFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                disabledBackgroundColor:
                    AppColors.accent.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: _feeding
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.background)),
                        SizedBox(width: 10),
                        Text('Dispensing feed...',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Text(_fed ? '✓ Feed Dispensed' : 'Trigger Manual Feed',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final FeedSchedule schedule;
  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: schedule.isEnabled
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.schedule,
                color: schedule.isEnabled
                    ? AppColors.primary
                    : AppColors.textLight,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.timeLabel,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  '${schedule.portionGrams.toStringAsFixed(0)}g · ${schedule.durationSeconds}s servo',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: schedule.isEnabled,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: (_) => state.toggleSchedule(schedule.id),
          ),
        ],
      ),
    );
  }
}

class _FeedLogTile extends StatelessWidget {
  final FeedLog log;
  const _FeedLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(log.timestamp);
    final timeAgo =
        diff.inHours > 0 ? '${diff.inHours}h ago' : '${diff.inMinutes}m ago';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            log.trigger == 'manual' ? Icons.touch_app_outlined : Icons.schedule,
            color: AppColors.textLight,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${log.pondName} · ${log.portionGrams.toStringAsFixed(0)}g',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text('${log.trigger} · $timeAgo',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
          if (!log.synced)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Offline',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            )
          else
            const Icon(Icons.cloud_done_outlined,
                color: AppColors.textLight, size: 16),
        ],
      ),
    );
  }
}
