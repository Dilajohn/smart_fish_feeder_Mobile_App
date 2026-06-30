import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class QrPairScreen extends StatefulWidget {
  const QrPairScreen({super.key});

  @override
  State<QrPairScreen> createState() => _QrPairScreenState();
}

class _QrPairScreenState extends State<QrPairScreen> {
  bool _claimed = false;
  bool _scanning = false;
  bool _scanned = false;
  final TextEditingController _nameCtrl = TextEditingController(text: 'Pond C Feeder');

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _simulateScan() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() { _scanning = false; _scanned = true; });
  }

  void _claimDevice() async {
    setState(() => _claimed = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PAIRING · STEP ${_scanned ? "2" : "1"} OF 3',
                style: AppTextStyles.screenLabel),
            Text(_scanned ? 'Confirm Device' : 'Scan QR Code',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
        actions: [
          if (_scanned)
            Padding(
              padding: const EdgeInsets.only(right: 16),
<<<<<<< HEAD
              child: StatusBadge.success(),
=======
              child: StatusBadge.success('Scanned'),
>>>>>>> main
            ),
        ],
      ),
      body: Column(
        children: [
          if (_claimed)
            AlertBanner.success('✓ Feeder Node Claimed! Adding ${_nameCtrl.text} to multi-pond view...')
          else if (_scanned)
            AlertBanner.success('QR Code acknowledged & validated with server'),

          Expanded(
            child: _scanned ? _confirmView() : _scanView(),
          ),

          // Bottom action area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: Column(
              children: [
                if (_scanned) ...[
                  ElevatedButton(
                    onPressed: _claimed ? null : _claimDevice,
                    child: Text(_claimed ? 'Registering Feeder Node...' : 'Confirm & Claim Device'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() { _scanned = false; _claimed = false; }),
                    child: const Text('Scan a different device sticker',
                        style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _scanning ? null : _simulateScan,
                    icon: _scanning
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(_scanning ? 'Scanning...' : 'Open Camera Scanner'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
                    child: const Text('Skip for now', style: TextStyle(color: AppColors.textLight)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mock QR scanner frame
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Center(
                  child: _scanning
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: AppColors.accent),
                            const SizedBox(height: 16),
                            const Text('Scanning device sticker...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
<<<<<<< HEAD
                            Icon(Icons.qr_code_2, color: AppColors.accent.withOpacity(0.6), size: 80),
=======
                            Icon(Icons.qr_code_2, color: AppColors.accent.withValues(alpha: 0.6), size: 80),
>>>>>>> main
                            const SizedBox(height: 12),
                            const Text('Point camera at feeder QR sticker', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                ),
                // Corner brackets
                ..._corners(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Where to find the QR code', style: AppTextStyles.cardTitle),
                SizedBox(height: 12),
                _Step(num: '1', text: 'Locate the white sticker on the side of your feeder device'),
                SizedBox(height: 8),
                _Step(num: '2', text: 'Open the camera scanner and align with the QR code'),
                SizedBox(height: 8),
                _Step(num: '3', text: 'Hold steady — the app will auto-detect and pair'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), shape: BoxShape.circle),
                  child: const Icon(Icons.qr_code, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 10),
                const Text('Feeder Node #003', style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text('SFF-003-KLA', style: AppTextStyles.monoBadge.copyWith(color: AppColors.textLight)),
                const Divider(height: 24),
<<<<<<< HEAD
                DataRow(label: 'Motherboard Specs', value: 'Uno + ESP8266 Node'),
                DataRow(label: 'Micro-Code Version', value: 'v1.2.4 Standard'),
                DataRow(
=======
                InfoRow(label: 'Motherboard Specs', value: 'Uno + ESP8266 Node'),
                InfoRow(label: 'Micro-Code Version', value: 'v1.2.4 Standard'),
                InfoRow(
>>>>>>> main
                  label: 'Network Status',
                  value: '',
                  trailing: StatusBadge.warning('Unclaimed'),
                ),
<<<<<<< HEAD
                DataRow(label: 'Device Registered', value: 'June 18, 2026'),
=======
                InfoRow(label: 'Device Registered', value: 'June 18, 2026'),
>>>>>>> main
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RENAME / ASSIGN POND NICKNAME', style: AppTextStyles.screenLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Pond C Feeder'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const c = Color(0xFF34D399);
    const s = 28.0;
    const t = 3.0;
    return [
      Positioned(top: 16, left: 16, child: _corner(s, t, c, top: true, left: true)),
      Positioned(top: 16, right: 16, child: _corner(s, t, c, top: true, left: false)),
      Positioned(bottom: 16, left: 16, child: _corner(s, t, c, top: false, left: true)),
      Positioned(bottom: 16, right: 16, child: _corner(s, t, c, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double thickness, Color color, {required bool top, required bool left}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> main
