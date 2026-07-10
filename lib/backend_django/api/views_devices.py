from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Device, Pond
from .serializers import DeviceSerializer
import secrets
from django.utils import timezone

@api_view(['POST'])
def register_device(request):
    # Expects JSON: {"serial": "FEEDER-001", "name": "Main Pond"}
    data = request.data
    serial = data.get('serial')
    name = data.get('name', '')
    if not serial:
        return Response({'detail':'serial required'}, status=status.HTTP_400_BAD_REQUEST)
    token = secrets.token_hex(24)
    device, created = Device.objects.update_or_create(serial=serial, defaults={'name': name, 'token': token, 'last_seen': timezone.now()})
    serializer = DeviceSerializer(device)
    return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

@api_view(['GET'])
def list_devices(request):
    devices = Device.objects.all()
    return Response(DeviceSerializer(devices, many=True).data)
