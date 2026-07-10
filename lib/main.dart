import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/qr_pair_screen.dart';
import 'screens/main_shell.dart';
import 'screens/extra_screens.dart';
import 'screens/calibration_screen.dart';
import 'screens/offline_mode_screen.dart';
import 'screens/add_schedule_screen.dart';
import 'screens/water_alert_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/db_settings_screen.dart';
import 'screens/api_settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SmartFishFeederApp(),
    ),
  );
}

class SmartFishFeederApp extends StatelessWidget {
  const SmartFishFeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Fish Feeder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/qr-pair': (_) => const QrPairScreen(),
        '/main': (_) => const MainShell(),
        '/cooldown': (_) => const CooldownLockScreen(),
        '/sync': (_) => const SyncStatusScreen(),
        '/export-log': (_) => const ExportLogScreen(),
        '/calibration': (_) => const CalibrationScreen(),
        '/offline': (_) => const OfflineModeScreen(),
        '/add-schedule': (_) => const AddScheduleScreen(),
        '/water-alert': (_) => const WaterAlertScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/db-settings': (_) => const DbSettingsScreen(),
        '/api-settings': (_) => const ApiSettingsScreen(),
      },
    );
  }
}
