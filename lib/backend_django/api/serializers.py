from rest_framework import serializers
from .models import Pond, FeedSchedule, FeedLog, Command, Device

class PondSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pond
        fields = '__all__'

class FeedScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedSchedule
        fields = '__all__'

class FeedLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedLog
        fields = '__all__'

class CommandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Command
        fields = '__all__'

class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ['serial', 'name', 'token', 'last_seen']
