import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DeviceHealthScreen extends StatelessWidget {
  const DeviceHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final device = state.deviceInfo;
    final fw = state.firmwareState;

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${device.serial} · ${device.pondName}', style: AppTextStyles.screenLabel),
            const Text('Device Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: Text(device.firmwareVersion, style: AppTextStyles.monoBadge.copyWith(color: AppColors.textMedium)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Firmware update state banner
            if (fw == 'updating')
              const AlertBanner(
                message: 'Flashing firmware specs... 45%',
                color: AppColors.warning,
                bgColor: Color(0xFFFFFBEB),
                icon: Icons.sync,
              )
            else if (fw == 'updated')
              AlertBanner.success('Firmware up to date (${device.latestFirmware} stable)')
            else
              AlertBanner.success('All hardware systems operational'),

            const SizedBox(height: 14),

            // Hardware diagnostics
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HARDWARE DIAGNOSTICS', style: AppTextStyles.screenLabel),
                  const SizedBox(height: 12),
                  ...device.hardwareStatus.entries.map((e) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: AppTextStyles.bodySmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(e.value,
                                      style: const TextStyle(color: AppColors.online, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      )),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Connectivity telemetry
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONNECTIVITY TELEMETRY', style: AppTextStyles.screenLabel),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'WiFi RSSI Strength',
                    value: '${device.wifiRssi} dBm · ${device.rssiLabel}',
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Gateway Ping Time', value: '${device.pingMs} ms'),
                  const Divider(height: 1),
                  const InfoRow(label: 'Last Heartbeat', value: '30s ago'),
                  const Divider(height: 1),
                  InfoRow(label: 'Continuous Uptime', value: device.uptimeLabel),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Firmware update card
            if (device.firmwareUpdateAvailable && fw == 'idle')
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.system_update_outlined, color: AppColors.info, size: 18),
                        const SizedBox(width: 8),
                        Text('${device.latestFirmware} Available', style: AppTextStyles.cardTitle),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Increases hardware clock synchronization rates across Lake Victoria clusters.',
                      style: TextStyle(color: AppColors.textMedium, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: fw != 'idle' ? null : () => state.triggerFirmwareUpdate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: fw == 'updated' ? const Color(0xFF16A34A) : AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (fw == 'updating') ...[
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    const SizedBox(width: 10),
                  ] else if (fw == 'updated') ...[
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    fw == 'updating'
                        ? 'Flashing firmware...'
                        : fw == 'updated'
                            ? 'System Fully Patched'
                            : 'Update Firmware Now',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
