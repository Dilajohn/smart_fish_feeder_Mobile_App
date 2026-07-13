"""
Smart Fish Feeder — Django ORM Models
All tables mirror the Flutter/PostgreSQL schema exactly.
Running `python manage.py migrate` auto-creates the database.
"""
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator, MaxValueValidator


class User(AbstractUser):
    """Extended user — adds phone and farm name."""
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True)
    farm_name = models.CharField(max_length=120, blank=True)
    USERNAME_FIELD  = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'users'

    def __str__(self):
        return self.email


class Pond(models.Model):
    """A single fish pond with an associated feeder device."""
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ponds', null=True, blank=True)
    name         = models.CharField(max_length=100, unique=True)
    feeder_serial= models.CharField(max_length=50)
    food_percent = models.IntegerField(default=100, validators=[MinValueValidator(0), MaxValueValidator(100)])
    next_feed_time = models.CharField(max_length=20, default='Offline')
    water_temp   = models.FloatField(default=25.0)
    is_online    = models.BooleanField(default=False)
    last_seen    = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'ponds'
        ordering = ['name']

    def __str__(self):
        return self.name


class FeedSchedule(models.Model):
    """Scheduled automatic feeding event."""
    id       = models.CharField(max_length=50, primary_key=True)
    pond     = models.ForeignKey(Pond, on_delete=models.CASCADE, related_name='schedules', to_field='name', db_column='pond_name')
    hour     = models.IntegerField(validators=[MinValueValidator(0), MaxValueValidator(23)])
    minute   = models.IntegerField(validators=[MinValueValidator(0), MaxValueValidator(59)])
    duration_seconds = models.IntegerField(validators=[MinValueValidator(1)])
    portion_grams    = models.IntegerField(validators=[MinValueValidator(1)])
    is_enabled = models.BooleanField(default=True)
    # 7-element boolean array: Mon-Sun
    weekdays   = models.JSONField(default=list)

    class Meta:
        db_table = 'feed_schedules'
        ordering = ['hour', 'minute']

    def __str__(self):
        return f'{self.pond_id} {self.hour:02d}:{self.minute:02d}'


class FeedLog(models.Model):
    """Record of a completed feeding event."""
    TRIGGER_CHOICES = [('scheduled', 'Scheduled'), ('manual', 'Manual')]
    id           = models.CharField(max_length=50, primary_key=True)
    pond_name    = models.CharField(max_length=100, db_index=True)
    timestamp    = models.DateTimeField(auto_now_add=True, db_index=True)
    portion_grams = models.FloatField(validators=[MinValueValidator(0)])
    trigger_type  = models.CharField(max_length=20, choices=TRIGGER_CHOICES)
    synced        = models.BooleanField(default=True)

    class Meta:
        db_table = 'feed_logs'
        ordering = ['-timestamp']

    def __str__(self):
        return f'{self.pond_name} {self.timestamp:%Y-%m-%d %H:%M}'


class DeviceInfo(models.Model):
    """Hardware status snapshot for a feeder device."""
    serial         = models.CharField(max_length=50, primary_key=True)
    pond_name      = models.CharField(max_length=100)
    firmware_version = models.CharField(max_length=20)
    latest_firmware  = models.CharField(max_length=20)
    wifi_rssi        = models.IntegerField()
    ping_ms          = models.IntegerField()
    uptime_seconds   = models.BigIntegerField(validators=[MinValueValidator(0)])
    hardware_status  = models.JSONField(default=dict)
    firmware_update_available = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'device_info'

    def __str__(self):
        return self.serial


class SyncStatus(models.Model):
    """EEPROM sync counters and cloud sync state."""
    pending_uploads   = models.IntegerField(default=0)
    failed_retries    = models.IntegerField(default=0)
    recovered_events  = models.IntegerField(default=0)
    last_sync_time    = models.DateTimeField(auto_now=True)
    eeprom_healthy    = models.BooleanField(default=True)
    eeprom_used_bytes = models.IntegerField(default=0)
    eeprom_total_bytes= models.IntegerField(default=4096)

    class Meta:
        db_table = 'sync_status'


class DeviceCommand(models.Model):
    """Pending commands queued for delivery to the ESP8266 device."""
    STATUS = [('pending', 'Pending'), ('delivered', 'Delivered'), ('failed', 'Failed')]
    TYPES  = [('feed_now', 'Feed Now'), ('update_schedule', 'Update Schedule'),
              ('firmware_update', 'Firmware Update'), ('sync', 'Sync EEPROM')]
    device_serial = models.CharField(max_length=50, db_index=True)
    command_type  = models.CharField(max_length=30, choices=TYPES)
    payload       = models.JSONField(default=dict)
    status        = models.CharField(max_length=20, choices=STATUS, default='pending')
    created_at    = models.DateTimeField(auto_now_add=True)
    delivered_at  = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'device_commands'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.device_serial} · {self.command_type} · {self.status}'


class Telemetry(models.Model):
    """Raw telemetry readings pushed from the ESP8266."""
    device_serial  = models.CharField(max_length=50, db_index=True)
    food_level_pct = models.FloatField()
    water_temp     = models.FloatField(null=True, blank=True)
    wifi_rssi      = models.IntegerField(null=True, blank=True)
    recorded_at    = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'telemetry'
        ordering = ['-recorded_at']
