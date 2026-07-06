import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_fish_feeder/main.dart';
import 'package:smart_fish_feeder/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const SmartFishFeederApp(),
      ),
    );
    // Splash screen should show brand name
    expect(find.text('Smart Fish Feeder'), findsOneWidget);
  });

  test('AppState initializes with 3 ponds', () {
    final state = AppState();
    expect(state.ponds.length, 3);
  });

  test('AppState detects offline pond', () {
    final state = AppState();
    expect(state.hasOfflinePond, true);
  });

  test('AppState toggle schedule changes enabled state', () {
    final state = AppState();
    final original = state.schedules.first.isEnabled;
    state.toggleSchedule(state.schedules.first.id);
    expect(state.schedules.first.isEnabled, !original);
  });

  test('Hopper level updates correctly', () {
    final state = AppState();
    state.setHopperLevel(42.0);
    expect(state.hopperLevel, 42.0);
  });
}
