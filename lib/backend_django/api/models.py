from django.db import models

class Pond(models.Model):
    id = models.CharField(primary_key=True, max_length=50)
    name = models.CharField(max_length=100)
    serial = models.CharField(max_length=100)
    hopper_percent = models.FloatField(default=100.0)

    def __str__(self):
        return self.name

class FeedSchedule(models.Model):
    id = models.CharField(primary_key=True, max_length=50)
    pond = models.ForeignKey(Pond, on_delete=models.CASCADE, related_name='schedules')
    time = models.CharField(max_length=32, null=True, blank=True)
    amount_grams = models.FloatField(null=True, blank=True)

class FeedLog(models.Model):
    id = models.CharField(primary_key=True, max_length=50)
    pond = models.ForeignKey(Pond, on_delete=models.SET_NULL, null=True, blank=True)
    serial = models.CharField(max_length=100)
    amount_grams = models.FloatField()
    timestamp = models.DateTimeField()

class Command(models.Model):
    id = models.CharField(primary_key=True, max_length=50)
    serial = models.CharField(max_length=100)
    command = models.CharField(max_length=100)
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

class Device(models.Model):
    # Represents a physical feeder device and a per-device token for authentication
    serial = models.CharField(primary_key=True, max_length=100)
    name = models.CharField(max_length=100, blank=True)
    token = models.CharField(max_length=64, unique=True)
    last_seen = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.serial} ({self.name})" 
