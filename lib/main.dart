import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/qr_pair_screen.dart';
import 'screens/main_shell.dart';
import 'screens/extra_screens.dart';

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
        '/onboarding': (_) => const OnboardingScreen(),
        '/qr-pair': (_) => const QrPairScreen(),
        '/main': (_) => const MainShell(),
        '/cooldown': (_) => const CooldownLockScreen(),
        '/sync': (_) => const SyncStatusScreen(),
        '/export-log': (_) => const ExportLogScreen(),
      },
    );
  }
}
