from django.urls import path
from . import views
from . import views_extra
from . import views_devices

urlpatterns = [
    path('devices/register/', views_devices.register_device),
    path('devices/', views_devices.list_devices),
    path('ponds/', views.ponds_view),
    path('ponds/<str:pond_id>/trigger-feed/', views_extra.trigger_feed),
    path('schedules/', views.schedules_view),
    path('telemetry/', views.telemetry_view),
    path('feed-logs/', views.feed_logs_view),
    path('commands/<str:serial>/', views.post_command),
    path('commands/<str:serial>/pull/', views.pull_commands),
    path('commands/<str:serial>/ack/', views.ack_command),
]
