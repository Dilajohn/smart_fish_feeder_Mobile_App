import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';
import '../models/models.dart';

class MultiPondScreen extends StatelessWidget {
  const MultiPondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ponds = state.ponds;

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FARM DASHBOARD', style: AppTextStyles.screenLabel),
            const Text('All Ugandan Ponds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: Text('${ponds.length} Feeders', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.hasOfflinePond)
            AlertBanner.warning('Warning: Pond B feeder is offline! Last ping: 8h ago.'),
          if (state.hasCriticalFood)
            AlertBanner.warning('Pond C hopper critically low (19%). Schedule refill today.'),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ponds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _PondCard(pond: ponds[index]),
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final nextId = ponds.length + 1;
                      context.read<AppState>().addPond(PondModel(
                        id: nextId,
                        name: 'Pond ${String.fromCharCode(64 + nextId)} Pilot',
                        feederSerial: 'SFF-00$nextId-KLA',
                        foodPercent: 100,
                        nextFeedTime: '12:00 PM',
                        waterTemp: 24.9,
                        isOnline: true,
                        lastSeen: DateTime.now(),
                      ));
                    },
                    child: const Text('+ Add New Pond Node'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/qr-pair'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PondCard extends StatelessWidget {
  final PondModel pond;
  const _PondCard({required this.pond});

  @override
  Widget build(BuildContext context) {
    final isLow = pond.isOnline && pond.isFoodLow;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pond.isOnline ? const Color(0xFFE2E8F0) : const Color(0xFFFEE2E2),
        ),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pond.isOnline ? AppColors.online : AppColors.offline,
                  ),
                ),
                const SizedBox(width: 8),
                Text(pond.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(width: 6),
                Text('(${pond.feederSerial})', style: AppTextStyles.monoBadge.copyWith(color: AppColors.textLight, fontSize: 10)),
                const Spacer(),
                pond.isOnline ? StatusBadge.online() : StatusBadge.offline(),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _PondStat(
                  label: 'Hopper Food',
                  value: pond.isOnline ? '${pond.foodPercent.toStringAsFixed(0)}%' : '—',
                  valueColor: isLow ? AppColors.offline : AppColors.textDark,
                  isAlert: isLow,
                ),
                _divider(),
                _PondStat(
                  label: 'Next Feed',
                  value: pond.nextFeedTime,
                  valueColor: AppColors.textDark,
                ),
                _divider(),
                _PondStat(
                  label: 'Water Temp',
                  value: pond.isOnline ? '${pond.waterTemp}°C' : '—',
                  valueColor: AppColors.textDark,
                ),
              ],
            ),
          ),

          // Food level progress bar
          if (pond.isOnline)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pond.foodPercent / 100,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(isLow ? AppColors.offline : AppColors.primary),
                      minHeight: 5,
                    ),
                  ),
                  if (isLow)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('⚠ Food critically low — refill needed', style: TextStyle(color: AppColors.offline, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: const Color(0xFFE2E8F0));
}

class _PondStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isAlert;

  const _PondStat({required this.label, required this.value, required this.valueColor, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.screenLabel.copyWith(fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valueColor),
          ),
        ],
      ),
    );
  }
}
