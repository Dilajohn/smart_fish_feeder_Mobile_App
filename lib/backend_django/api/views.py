from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Pond, FeedSchedule, FeedLog, Command, Device
from .serializers import PondSerializer, FeedScheduleSerializer, FeedLogSerializer, CommandSerializer, DeviceSerializer
from django.utils import timezone
import uuid

@api_view(['GET','POST'])
def ponds_view(request):
    if request.method == 'GET':
        ponds = Pond.objects.all()
        return Response(PondSerializer(ponds, many=True).data)
    else:
        # Require authentication for write
        if not request.user or not request.user.is_authenticated:
            return Response({'detail': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
        data = request.data
        if 'id' not in data:
            data['id'] = str(uuid.uuid4())
        s = PondSerializer(data=data)
        s.is_valid(raise_exception=True)
        s.save()
        return Response(s.data, status=status.HTTP_201_CREATED)

@api_view(['GET','POST'])
def schedules_view(request):
    if request.method == 'GET':
        qs = FeedSchedule.objects.all()
        return Response(FeedScheduleSerializer(qs, many=True).data)
    else:
        if not request.user or not request.user.is_authenticated:
            return Response({'detail': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
        data = request.data
        if 'id' not in data:
            data['id'] = str(uuid.uuid4())
        s = FeedScheduleSerializer(data=data)
        s.is_valid(raise_exception=True)
        s.save()
        return Response(s.data, status=status.HTTP_201_CREATED)

@api_view(['POST'])
def telemetry_view(request):
    # Telemetry from devices: prefer device-token auth (header: Device-Token). If present, validate token.
    data = request.data
    serial = data.get('serial')
    hopper = data.get('hopper_percent')
    device_token = request.META.get('HTTP_DEVICE_TOKEN')
    device = None
    if device_token:
        device = Device.objects.filter(token=device_token).first()
        if device and device.serial != serial:
            return Response({'detail':'token does not match device serial'}, status=status.HTTP_401_UNAUTHORIZED)
    # update last_seen
    if device:
        device.last_seen = timezone.now()
        device.save()

    if serial and hopper is not None:
        try:
            pond = Pond.objects.filter(serial=serial).first()
            if pond:
                pond.hopper_percent = hopper
                pond.save()
        except Exception:
            pass
    return Response({'status': 'received'})

@api_view(['GET','POST'])
def feed_logs_view(request):
    if request.method == 'GET':
        logs = FeedLog.objects.all()
        return Response(FeedLogSerializer(logs, many=True).data)
    else:
        if not request.user or not request.user.is_authenticated:
            return Response({'detail': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
        data = request.data
        if 'id' not in data:
            data['id'] = str(uuid.uuid4())
        if 'timestamp' not in data:
            data['timestamp'] = timezone.now()
        s = FeedLogSerializer(data=data)
        s.is_valid(raise_exception=True)
        s.save()
        return Response(s.data, status=status.HTTP_201_CREATED)

@api_view(['POST'])
def post_command(request, serial):
    # Devices can post commands anonymously (if you choose). Require auth for cloud-originated commands
    if not request.user or not request.user.is_authenticated:
        # allow device-originated commands if no auth but limit fields
        data = request.data
        data['serial'] = serial
        if 'id' not in data:
            data['id'] = str(uuid.uuid4())
        s = CommandSerializer(data=data)
        s.is_valid(raise_exception=True)
        s.save()
        return Response({'status': 'queued', 'id': s.data['id']}, status=status.HTTP_201_CREATED)
    data = request.data
    data['serial'] = serial
    if 'id' not in data:
        data['id'] = str(uuid.uuid4())
    s = CommandSerializer(data=data)
    s.is_valid(raise_exception=True)
    s.save()
    return Response({'status': 'queued', 'id': s.data['id']}, status=status.HTTP_201_CREATED)

@api_view(['GET'])
def pull_commands(request, serial):
    # Require device token to pull commands
    device_token = request.META.get('HTTP_DEVICE_TOKEN')
    if not device_token:
        return Response({'detail':'Device-Token header required'}, status=status.HTTP_401_UNAUTHORIZED)
    device = Device.objects.filter(token=device_token).first()
    if not device or device.serial != serial:
        return Response({'detail':'Invalid device token'}, status=status.HTTP_401_UNAUTHORIZED)
    qs = Command.objects.filter(serial=serial)
    data = CommandSerializer(qs, many=True).data
    qs.delete()
    # update last_seen
    device.last_seen = timezone.now()
    device.save()
    return Response(data)

@api_view(['POST'])
def ack_command(request, serial):
    return Response({'status': 'acknowledged'})
