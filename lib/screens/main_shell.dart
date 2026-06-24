import 'package:flutter/material.dart';
import '../widgets/shared_widgets.dart';
import 'dashboard_screen.dart';
import 'multi_pond_screen.dart';
import 'refill_prediction_screen.dart';
import 'device_health_screen.dart';
import 'extra_screens.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = [
    DashboardScreen(),
    MultiPondScreen(),
    RefillPredictionScreen(),
    DeviceHealthScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
