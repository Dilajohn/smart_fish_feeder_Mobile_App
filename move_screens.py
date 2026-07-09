import os, shutil
base=r'c:\Users\USER\Desktop\smart_fish_feeder\lib\screens'
files=[
('dashboard_screen.dart','main/dashboard_screen.dart'),
('multi_pond_screen.dart','main/multi_pond_screen.dart'),
('refill_prediction_screen.dart','main/refill_prediction_screen.dart'),
('device_health_screen.dart','main/device_health_screen.dart'),
('add_schedule_screen.dart','analytics/add_schedule_screen.dart'),
('analytics_screen.dart','analytics/analytics_screen.dart'),
('offline_mode_screen.dart','diagnostics/offline_mode_screen.dart'),
('water_alert_screen.dart','diagnostics/water_alert_screen.dart'),
('calibration_screen.dart','diagnostics/calibration_screen.dart'),
('notifications_screen.dart','notifications/notifications_screen.dart'),
('profile_screen.dart','settings/profile_screen.dart'),
('db_settings_screen.dart','settings/db_settings_screen.dart'),
('login_screen.dart','auth/login_screen.dart'),
('onboarding_screen.dart','onboarding/onboarding_screen.dart'),
('splash_screen.dart','onboarding/splash_screen.dart'),
('qr_pair_screen.dart','onboarding/qr_pair_screen.dart'),
('extra_screens.dart','main/extra_screens.dart'),
('main_shell.dart','main/main_shell.dart'),
]
for src, dst in files:
    s=os.path.join(base,src)
    d=os.path.join(base,dst)
    if os.path.exists(s):
        os.makedirs(os.path.dirname(d), exist_ok=True)
        shutil.move(s, d)
