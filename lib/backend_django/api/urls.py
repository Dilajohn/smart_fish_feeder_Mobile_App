"""
Smart Fish Feeder — API URL Router
All routes under /api/v1/
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register('ponds',     views.PondViewSet,        basename='pond')
router.register('schedules', views.FeedScheduleViewSet, basename='schedule')
router.register('feed-logs', views.FeedLogViewSet,      basename='feedlog')
router.register('devices',   views.DeviceInfoViewSet,   basename='device')

urlpatterns = [
    # Health (public)
    path('health/', views.health_check, name='health'),

    # Auth (public)
    path('auth/register/',       views.RegisterView.as_view(),      name='auth-register'),
    path('auth/login/',          views.LoginView.as_view(),         name='auth-login'),
    path('auth/logout/',         views.LogoutView.as_view(),        name='auth-logout'),
    path('auth/password-reset/', views.PasswordResetView.as_view(), name='password-reset'),
    path('auth/verify-email/',   views.VerifyEmailView.as_view(),   name='verify-email'),

    # ── Hardware device endpoints (called by ESP32 firmware) ──
    # Step 1: device registers on first boot → receives its token
    path('devices/register/', views.device_register, name='device-register'),
    # Step 2: device polls for pending commands every 5 s
    path('devices/<str:serial>/poll/', views.device_poll_commands, name='device-poll'),

    # Command ACK — called by ESP32 after executing a command
    path('commands/<int:pk>/ack/', views.CommandAckView.as_view(), name='command-ack'),

    # Sync status
    path('sync-status/', views.SyncStatusView.as_view(), name='sync-status'),

    # Telemetry (posted by ESP32 every loop cycle)
    path('telemetry/', views.TelemetryView.as_view(), name='telemetry'),

    # Export
    path('export/', views.export_logs, name='export'),

    # ViewSet routes (ponds, schedules, feed-logs, devices)
    path('', include(router.urls)),
]
