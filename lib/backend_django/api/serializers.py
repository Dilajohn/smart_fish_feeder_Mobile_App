from django.contrib.auth import authenticate
from rest_framework import serializers
from rest_framework.authtoken.models import Token
from .models import User, Pond, FeedSchedule, FeedLog, DeviceInfo, SyncStatus, DeviceCommand, Telemetry


# ── Auth ──────────────────────────────────────────────────────
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    class Meta:
        model  = User
        fields = ['id', 'name', 'email', 'phone', 'password']
        extra_kwargs = {'name': {'source': 'first_name'}}

    def create(self, validated_data):
        name = validated_data.pop('first_name', '')
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=name,
            phone=validated_data.get('phone', ''),
        )
        return user


class LoginSerializer(serializers.Serializer):
    email    = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        user = authenticate(username=data['email'], password=data['password'])
        if not user:
            raise serializers.ValidationError('Invalid email or password.')
        token, _ = Token.objects.get_or_create(user=user)
        return {'token': token.key, 'user_id': user.id, 'email': user.email, 'name': user.first_name}


class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField()


class EmailVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    code  = serializers.CharField(max_length=6)


# ── Pond ──────────────────────────────────────────────────────
class PondSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Pond
        fields = '__all__'
        read_only_fields = ['owner', 'last_seen']


# ── Schedule ──────────────────────────────────────────────────
class FeedScheduleSerializer(serializers.ModelSerializer):
    time_label = serializers.SerializerMethodField()

    class Meta:
        model  = FeedSchedule
        fields = '__all__'

    def get_time_label(self, obj):
        h = obj.hour % 12 or 12
        period = 'AM' if obj.hour < 12 else 'PM'
        return f'{h}:{obj.minute:02d} {period}'


# ── Feed Log ──────────────────────────────────────────────────
class FeedLogSerializer(serializers.ModelSerializer):
    class Meta:
        model  = FeedLog
        fields = '__all__'


# ── Device ────────────────────────────────────────────────────
class DeviceInfoSerializer(serializers.ModelSerializer):
    uptime_label = serializers.SerializerMethodField()
    rssi_label   = serializers.SerializerMethodField()

    class Meta:
        model  = DeviceInfo
        fields = '__all__'

    def get_uptime_label(self, obj):
        s = obj.uptime_seconds
        return f'{s // 86400}d {(s % 86400) // 3600}h {(s % 3600) // 60}m'

    def get_rssi_label(self, obj):
        r = obj.wifi_rssi
        if r >= -60: return 'Excellent'
        if r >= -70: return 'Good'
        if r >= -80: return 'Fair'
        return 'Weak'


# ── Sync ─────────────────────────────────────────────────────
class SyncStatusSerializer(serializers.ModelSerializer):
    eeprom_fill_percent = serializers.SerializerMethodField()
    class Meta:
        model  = SyncStatus
        fields = '__all__'

    def get_eeprom_fill_percent(self, obj):
        if obj.eeprom_total_bytes == 0: return 0
        return round(obj.eeprom_used_bytes / obj.eeprom_total_bytes * 100, 1)


# ── Command ───────────────────────────────────────────────────
class DeviceCommandSerializer(serializers.ModelSerializer):
    class Meta:
        model  = DeviceCommand
        fields = '__all__'
        read_only_fields = ['created_at', 'delivered_at']


# ── Telemetry ─────────────────────────────────────────────────
class TelemetrySerializer(serializers.ModelSerializer):
    class Meta:
        model  = Telemetry
        fields = '__all__'
        read_only_fields = ['recorded_at']
