from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Pond, FeedSchedule, FeedLog, DeviceInfo, SyncStatus, DeviceCommand, Telemetry

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['email', 'first_name', 'phone', 'is_staff', 'date_joined']
    ordering = ['email']

@admin.register(Pond)
class PondAdmin(admin.ModelAdmin):
    list_display  = ['name', 'feeder_serial', 'food_percent', 'is_online', 'last_seen']
    list_filter   = ['is_online']
    search_fields = ['name', 'feeder_serial']

@admin.register(FeedSchedule)
class ScheduleAdmin(admin.ModelAdmin):
    list_display  = ['id', 'pond', 'hour', 'minute', 'portion_grams', 'is_enabled']
    list_filter   = ['is_enabled', 'pond']

@admin.register(FeedLog)
class FeedLogAdmin(admin.ModelAdmin):
    list_display  = ['id', 'pond_name', 'timestamp', 'portion_grams', 'trigger_type', 'synced']
    list_filter   = ['trigger_type', 'synced']
    ordering      = ['-timestamp']

@admin.register(DeviceInfo)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ['serial', 'pond_name', 'firmware_version', 'wifi_rssi', 'ping_ms', 'updated_at']

@admin.register(DeviceCommand)
class CommandAdmin(admin.ModelAdmin):
    list_display  = ['id', 'device_serial', 'command_type', 'status', 'created_at']
    list_filter   = ['status', 'command_type']
    ordering      = ['-created_at']

@admin.register(Telemetry)
class TelemetryAdmin(admin.ModelAdmin):
    list_display  = ['device_serial', 'food_level_pct', 'water_temp', 'wifi_rssi', 'recorded_at']
    ordering      = ['-recorded_at']

admin.site.register(SyncStatus)
