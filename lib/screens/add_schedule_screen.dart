import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';

/// Add Schedule — matches fish_feeder_extra_screens.html "Add schedule" checkpoint.
class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  String _portion = 'Medium'; // Small / Medium / Large
  String _selectedPond = 'Pond A';
  bool _enableImmediately = true;
  bool _syncNow = true;
  // 0=Mon, 1=Tue ... 6=Sun
  late final List<bool> _days = [true, false, true, false, true, false, false];
  bool _saving = false;

  static const _portions = {
    'Small': {'grams': 8, 'desc': '~8g per drop'},
    'Medium': {'grams': 15, 'desc': '~15g per drop'},
    'Large': {'grams': 22, 'desc': '~22g per drop'},
  };

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final grams     = _portions[_portion]!['grams'] as int;
    final state     = context.read<AppState>();
    final schedule  = FeedSchedule(
      id:              'sch-${DateTime.now().millisecondsSinceEpoch}',
      pondName:        _selectedPond,
      time:            _time,
      durationSeconds: (grams / 1.5).round(),
      portionGrams:    grams.toDouble(),
      isEnabled:       _enableImmediately,
      weekdays:        List.of(_days),
    );

    // Persist to backend (AppState.addSchedule calls ApiService.createSchedule)
    await state.addSchedule(schedule);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.dbOnline
              ? 'Schedule saved${_syncNow ? ' & synced to device' : ''}.'
              : 'Schedule saved locally (server offline — will sync when reconnected).',
        ),
        backgroundColor: state.dbOnline ? AppColors.online : AppColors.warning,
      ),
    );
    Navigator.pop(context);
  }

  String get _timeLabel {
    final h = _time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod;
    final m = _time.minute.toString().padLeft(2, '0');
    final p = _time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SCHEDULE MANAGER',
                style: TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            Text('New schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pond selector — live from state
            Consumer<AppState>(
              builder: (context, state, _) {
                final pondNames = state.ponds.map((p) => p.name).toList();
                if (!pondNames.contains(_selectedPond) && pondNames.isNotEmpty) {
                  _selectedPond = pondNames.first;
                }
                return DropdownButtonFormField<String>(
                  value: _selectedPond,
                  decoration: const InputDecoration(
                    labelText: 'Select Pond',
                    prefixIcon: Icon(Icons.water_outlined),
                  ),
                  items: pondNames
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedPond = v); },
                );
              },
            ),
            const SizedBox(height: 16),

            // Time
            const SectionHeader(label: 'Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Feed time',
                            style: TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_timeLabel,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time_filled_rounded, color: AppColors.textLight),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Days
            const SectionHeader(label: 'Days'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final selected = _days[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _days[i] = !_days[i]),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.primary : Colors.white,
                        border: Border.all(
                          color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 18),

            // Portion size
            const SectionHeader(label: 'Portion size'),
            const SizedBox(height: 8),
            ..._portions.entries.map((entry) {
              final selected = _portion == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _portion = entry.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFDCFCE7) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: selected ? AppColors.primary : AppColors.textDark,
                              )),
                          Text('${entry.value['grams']}g',
                              style: TextStyle(
                                fontSize: 11,
                                color: selected ? AppColors.primary : AppColors.textLight,
                              )),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.primary : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                          color: selected ? AppColors.primary : Colors.transparent,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 18),

            // Options
            const SectionHeader(label: 'Options'),
            const SizedBox(height: 8),
            _OptionRow(
              label: 'Enable immediately',
              value: _enableImmediately,
              onChanged: (v) => setState(() => _enableImmediately = v),
            ),
            _OptionRow(
              label: 'Sync to device now',
              value: _syncNow,
              onChanged: (v) => setState(() => _syncNow = v),
            ),

            const SizedBox(height: 20),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Saving…'),
                      ],
                    )
                  : const Text('Save schedule'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _OptionRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ),
          Switch.adaptive(value: value, activeTrackColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}