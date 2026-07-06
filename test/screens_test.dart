// Smoke tests for every screen in the app — verifies each route builds
// without throwing and that core text fixtures render.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_fish_feeder/services/app_state.dart';
import 'package:smart_fish_feeder/models/models.dart';

import 'package:smart_fish_feeder/screens/splash_screen.dart';
import 'package:smart_fish_feeder/screens/login_screen.dart';
import 'package:smart_fish_feeder/screens/onboarding_screen.dart';
import 'package:smart_fish_feeder/screens/qr_pair_screen.dart';
import 'package:smart_fish_feeder/screens/dashboard_screen.dart';
import 'package:smart_fish_feeder/screens/multi_pond_screen.dart';
import 'package:smart_fish_feeder/screens/refill_prediction_screen.dart';
import 'package:smart_fish_feeder/screens/device_health_screen.dart';
import 'package:smart_fish_feeder/screens/extra_screens.dart';
import 'package:smart_fish_feeder/screens/calibration_screen.dart';
import 'package:smart_fish_feeder/screens/offline_mode_screen.dart';
import 'package:smart_fish_feeder/screens/add_schedule_screen.dart';
import 'package:smart_fish_feeder/screens/water_alert_screen.dart';
import 'package:smart_fish_feeder/screens/analytics_screen.dart';
import 'package:smart_fish_feeder/screens/notifications_screen.dart';
import 'package:smart_fish_feeder/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(home: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  // ── Existing screens ───────────────────────────────────────
  testWidgets('SplashScreen renders brand title', (tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));
    expect(find.text('Smart Fish Feeder'), findsOneWidget);
  });

  testWidgets('LoginScreen renders email/password + Sign in', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('OnboardingScreen renders feature tiles + CTA', (tester) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.text('Smart Fish Feeder'), findsWidgets);
    expect(find.text('Configure First Feeder Node'), findsOneWidget);
    expect(find.text('Skip — Already set up'), findsOneWidget);
  });

  testWidgets('QrPairScreen renders Scan + steps', (tester) async {
    await tester.pumpWidget(_wrap(const QrPairScreen()));
    expect(find.text('Open Camera Scanner'), findsOneWidget);
    expect(find.text('Where to find the QR code'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders manual feed trigger', (tester) async {
    await tester.pumpWidget(_wrap(const DashboardScreen()));
    expect(find.text('Feed Now'), findsOneWidget);
    expect(find.text('Feed Schedules'), findsOneWidget);
  });

  testWidgets('MultiPondScreen renders pond cards + Add button', (tester) async {
    await tester.pumpWidget(_wrap(const MultiPondScreen()));
    expect(find.text('+ Add New Pond Node'), findsOneWidget);
    expect(find.text('All Ugandan Ponds'), findsOneWidget);
  });

  testWidgets('RefillPredictionScreen renders ring + summary', (tester) async {
    await tester.pumpWidget(_wrap(const RefillPredictionScreen()));
    expect(find.text('Refill Prediction'), findsOneWidget);
    expect(find.text('Prediction Summary'), findsOneWidget);
  });

  testWidgets('DeviceHealthScreen renders firmware info', (tester) async {
    await tester.pumpWidget(_wrap(const DeviceHealthScreen()));
    expect(find.text('Device Health'), findsOneWidget);
    expect(find.text('HARDWARE DIAGNOSTICS'), findsOneWidget);
  });

  testWidgets('CooldownLockScreen renders lock visual', (tester) async {
    await tester.pumpWidget(_wrap(const CooldownLockScreen()));
    expect(find.text('Cooldown Lock'), findsOneWidget);
  });

  testWidgets('SyncStatusScreen renders counters', (tester) async {
    await tester.pumpWidget(_wrap(const SyncStatusScreen()));
    expect(find.text('Data Sync Status'), findsOneWidget);
    expect(find.text('SYNC COUNTERS'), findsOneWidget);
  });

  testWidgets('ExportLogScreen renders format picker', (tester) async {
    await tester.pumpWidget(_wrap(const ExportLogScreen()));
    expect(find.text('Export Feed Log'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
  });

  testWidgets('MenuScreen renders screens directory with 18 entries', (tester) async {
    await tester.pumpWidget(_wrap(const MenuScreen()));
    expect(find.text('Screens Directory'), findsOneWidget);
    expect(find.text('18 Screens'), findsOneWidget);
  });

  // ── New screens (added to match HTML checkpoints) ──────────
  testWidgets('CalibrationScreen renders portion sizes', (tester) async {
    await tester.pumpWidget(_wrap(const CalibrationScreen()));
    expect(find.text('Calibrate portions'), findsOneWidget);
    expect(find.text('Small'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
  });

  testWidgets('OfflineModeScreen renders RTC status + pending events', (tester) async {
    await tester.pumpWidget(_wrap(const OfflineModeScreen()));
    expect(find.text('Offline mode'), findsOneWidget);
    expect(find.text('RTC clock'), findsOneWidget);
    expect(find.text('Schedule loaded'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
  });

  testWidgets('AddScheduleScreen renders form', (tester) async {
    await tester.pumpWidget(_wrap(const AddScheduleScreen()));
    expect(find.text('New schedule'), findsOneWidget);
    expect(find.text('Save schedule'), findsOneWidget);
    expect(find.text('Small'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Large'), findsOneWidget);
  });

  testWidgets('WaterAlertScreen renders pH alert', (tester) async {
    await tester.pumpWidget(_wrap(const WaterAlertScreen()));
    expect(find.text('pH out of range'), findsOneWidget);
    expect(find.text('pH dropped to 5.8'), findsOneWidget);
    expect(find.text('Resolve & resume feeding'), findsOneWidget);
  });

  testWidgets('AnalyticsScreen renders weekly stats', (tester) async {
    await tester.pumpWidget(_wrap(const AnalyticsScreen()));
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Total feeds'), findsOneWidget);
    expect(find.text('DAILY FEED (GRAMS)'), findsOneWidget);
  });

  testWidgets('NotificationsScreen renders Today/Yesterday', (tester) async {
    await tester.pumpWidget(_wrap(const NotificationsScreen()));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Food level critical'), findsOneWidget);
    expect(find.text('Device went offline'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders profile + system', (tester) async {
    await tester.pumpWidget(_wrap(const ProfileScreen()));
    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('GROUP21'), findsOneWidget);
    expect(find.text('farmer@pondA.ug'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
  });

  // ── Functional / state checks ─────────────────────────────
  test('AppState.addSchedule increases schedule count', () {
    final state = AppState();
    final before = state.schedules.length;
    state.addSchedule(FeedSchedule(
      id: 't-1',
      pondName: 'Pond Z',
      time: const TimeOfDay(hour: 9, minute: 0),
      durationSeconds: 5,
      portionGrams: 50,
      isEnabled: true,
      weekdays: List.filled(7, true),
    ));
    expect(state.schedules.length, before + 1);
  });

  test('AppState.addPond registers new pond', () {
    final state = AppState();
    final before = state.ponds.length;
    state.addPond(PondModel(
      id: 99,
      name: 'Pond X',
      feederSerial: 'SFF-099-KLA',
      foodPercent: 50,
      nextFeedTime: '10:00 AM',
      waterTemp: 22.5,
      isOnline: true,
      lastSeen: DateTime.now(),
    ));
    expect(state.ponds.length, before + 1);
  });

  test('FeedSchedule.timeLabel renders 12-hour format', () {
    final s = FeedSchedule(
      id: 't',
      pondName: 'Pond A',
      time: const TimeOfDay(hour: 13, minute: 5),
      durationSeconds: 8,
      portionGrams: 120,
      isEnabled: true,
      weekdays: List.filled(7, true),
    );
    expect(s.timeLabel, '1:05 PM');
  });

  test('PondModel.isFoodLow reflects threshold', () {
    final low = PondModel(
      id: 1, name: 'P', feederSerial: 'X',
      foodPercent: 10, nextFeedTime: '12 PM', waterTemp: 24,
      isOnline: true, lastSeen: DateTime.now(),
    );
    final ok = low.copyWith(foodPercent: 80);
    expect(low.isFoodLow, true);
    expect(ok.isFoodLow, false);
  });

  test('DeviceInfo.rssiLabel buckets correctly', () {
    const base = DeviceInfo(
      serial: 'X',
      pondName: 'P',
      firmwareVersion: 'v1',
      latestFirmware: 'v1',
      wifiRssi: -50,
      pingMs: 100,
      uptime: Duration(hours: 1),
      hardwareStatus: {},
      firmwareUpdateAvailable: false,
    );
    expect(base.rssiLabel, 'Excellent');
  });
}