"""
Smart Fish Feeder — API Views
All endpoints are protected by TokenAuthentication except:
  POST /auth/register/
  POST /auth/login/
  GET  /health/
  POST /devices/register/   ← called by ESP32 firmware on first boot
"""
from django.utils import timezone
from django.contrib.auth import authenticate
from rest_framework import viewsets, status, generics
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
import secrets
from .models import (User, Pond, FeedSchedule, FeedLog,
                     DeviceInfo, SyncStatus, DeviceCommand, Telemetry)
from .serializers import (
    RegisterSerializer, LoginSerializer, PasswordResetSerializer,
    PondSerializer, FeedScheduleSerializer, FeedLogSerializer,
    DeviceInfoSerializer, SyncStatusSerializer, DeviceCommandSerializer,
    TelemetrySerializer,
)


# ── Health check (public) ─────────────────────────────────────
@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    return Response({'status': 'ok', 'service': 'smart-fish-feeder-api', 'version': '1.0.0'})


# ── Device self-registration (called by ESP32 on first boot) ──
@api_view(['POST'])
@permission_classes([AllowAny])
def device_register(request):
    """
    POST /api/v1/devices/register/
    Body: { "serial": "SFF-001-KLA", "name": "Feeder Node 1" }
    Returns: { "token": "<device_token>", "serial": "...", "created": true/false }

    ESP32 stores the returned token in NVS Preferences and sends it
    as the 'Device-Token' header on every subsequent request.
    """
    serial = request.data.get('serial', '').strip()
    name   = request.data.get('name', '').strip()

    if not serial:
        return Response({'detail': 'serial is required.'}, status=status.HTTP_400_BAD_REQUEST)

    # Get or create a DeviceInfo record. Generate a unique token on first registration.
    device, created = DeviceInfo.objects.get_or_create(
        serial=serial,
        defaults={
            'pond_name':       name or serial,
            'firmware_version':'unknown',
            'latest_firmware': 'unknown',
            'wifi_rssi':       0,
            'ping_ms':         0,
            'uptime_seconds':  0,
            'hardware_status': {},
            'firmware_update_available': False,
        }
    )

    # Attach a persistent device token (stored in a separate field via a simple approach)
    # We re-use the DRF Token model keyed on a synthetic user, or store as JSON in hardware_status
    # Simple approach: embed token in hardware_status['_device_token'] so no extra model needed
    if created or '_device_token' not in device.hardware_status:
        token = secrets.token_hex(32)
        device.hardware_status['_device_token'] = token
        device.save()
    else:
        token = device.hardware_status['_device_token']

    return Response({
        'token':   token,
        'serial':  serial,
        'created': created,
    }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


def _verify_device_token(request, serial):
    """Helper — validates Device-Token header against stored token. Returns True if valid."""
    incoming = request.META.get('HTTP_DEVICE_TOKEN', '')
    if not incoming:
        return False
    try:
        device = DeviceInfo.objects.get(serial=serial)
        stored = device.hardware_status.get('_device_token', '')
        return secrets.compare_digest(incoming, stored)
    except DeviceInfo.DoesNotExist:
        return False


# ── Auth ──────────────────────────────────────────────────────
class RegisterView(generics.CreateAPIView):
    """POST /auth/register/ — create new user account."""
    permission_classes = [AllowAny]
    serializer_class   = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user  = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response({'token': token.key, 'user_id': user.id, 'email': user.email}, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    """POST /auth/login/ — authenticate and return token."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data)


class LogoutView(APIView):
    """POST /auth/logout/ — delete auth token."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            request.user.auth_token.delete()
        except Exception:
            pass
        return Response({'detail': 'Successfully logged out.'})


class PasswordResetView(APIView):
    """POST /auth/password-reset/ — send password reset email."""
    permission_classes = [AllowAny]

    def post(self, request):
        # In production: trigger email with reset link. Stub for now.
        email = request.data.get('email', '')
        return Response({'detail': f'Password reset link sent to {email}.'})


class VerifyEmailView(APIView):
    """POST /auth/verify-email/ — verify OTP code."""
    permission_classes = [AllowAny]

    def post(self, request):
        # Stub: accept any 6-digit code for demo
        code  = request.data.get('code', '')
        if len(code) == 6:
            return Response({'detail': 'Email verified successfully.'})
        return Response({'detail': 'Invalid code.'}, status=status.HTTP_400_BAD_REQUEST)


# ── Ponds ─────────────────────────────────────────────────────
class PondViewSet(viewsets.ModelViewSet):
    """CRUD for fish ponds. Each user sees only their own ponds."""
    serializer_class   = PondSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Pond.objects.all()
        if not self.request.user.is_staff:
            qs = qs.filter(owner=self.request.user)
        return qs

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


# ── Schedules ─────────────────────────────────────────────────
class FeedScheduleViewSet(viewsets.ModelViewSet):
    """CRUD for feed schedules. Filter by ?pond=Pond+A"""
    serializer_class   = FeedScheduleSerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [DjangoFilterBackend]
    filterset_fields   = ['pond', 'is_enabled']

    def get_queryset(self):
        return FeedSchedule.objects.select_related('pond').all()

    @action(detail=True, methods=['patch'], url_path='toggle')
    def toggle(self, request, pk=None):
        schedule = self.get_object()
        schedule.is_enabled = not schedule.is_enabled
        schedule.save()
        return Response(FeedScheduleSerializer(schedule).data)


# ── Feed Logs ─────────────────────────────────────────────────
class FeedLogViewSet(viewsets.ModelViewSet):
    """Feed event log. Filter by ?pond=Pond+A&limit=30"""
    serializer_class   = FeedLogSerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [DjangoFilterBackend]
    filterset_fields   = ['pond_name', 'trigger_type', 'synced']

    def get_queryset(self):
        qs = FeedLog.objects.all()
        limit = self.request.query_params.get('limit')
        if limit:
            try:
                qs = qs[:int(limit)]
            except ValueError:
                pass
        return qs


# ── Devices ───────────────────────────────────────────────────
class DeviceInfoViewSet(viewsets.ModelViewSet):
    """Device hardware status. Keyed by serial number."""
    serializer_class   = DeviceInfoSerializer
    permission_classes = [IsAuthenticated]
    queryset           = DeviceInfo.objects.all()
    lookup_field       = 'serial'

    @action(detail=True, methods=['post'], url_path='feed')
    def feed_now(self, request, serial=None):
        """POST /devices/{serial}/feed/ — queue a manual feed command."""
        portion = request.data.get('portion_grams', 120)
        cmd = DeviceCommand.objects.create(
            device_serial=serial,
            command_type='feed_now',
            payload={'portion_grams': portion, 'triggered_by': request.user.email},
        )
        return Response({'command_id': cmd.id, 'status': 'queued', 'portion_grams': portion})

    @action(detail=True, methods=['post'], url_path='firmware-update')
    def firmware_update(self, request, serial=None):
        """POST /devices/{serial}/firmware-update/ — queue OTA update."""
        cmd = DeviceCommand.objects.create(
            device_serial=serial,
            command_type='firmware_update',
            payload={'requested_by': request.user.email},
        )
        return Response({'command_id': cmd.id, 'status': 'queued'})

    @action(detail=True, methods=['post'], url_path='sync')
    def sync(self, request, serial=None):
        """POST /devices/{serial}/sync/ — trigger EEPROM sync upload."""
        cmd = DeviceCommand.objects.create(
            device_serial=serial,
            command_type='sync',
            payload={},
        )
        return Response({'command_id': cmd.id, 'status': 'queued'})

    @action(detail=True, methods=['get'], url_path='commands')
    def pending_commands(self, request, serial=None):
        """GET /devices/{serial}/commands/ — ESP8266 polls this."""
        cmds = DeviceCommand.objects.filter(
            device_serial=serial, status='pending'
        ).order_by('created_at')
        return Response(DeviceCommandSerializer(cmds, many=True).data)


# ── Command ACK (user/app side — kept for compatibility) ──────
class CommandAckView(DeviceCommandAckView):
    """Alias kept so existing URL conf still works."""
    pass


# ── Sync Status ───────────────────────────────────────────────
class SyncStatusView(generics.RetrieveUpdateAPIView):
    """GET/PATCH /sync-status/ — EEPROM + cloud sync counters."""
    serializer_class   = SyncStatusSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        obj, _ = SyncStatus.objects.get_or_create(pk=1)
        return obj


# ── Telemetry ─────────────────────────────────────────────────
class TelemetryView(generics.CreateAPIView):
    """
    POST /api/v1/telemetry/
    Accepts both user Token auth (Flutter app) and Device-Token header (ESP32).
    Body: { "device_serial": "SFF-001-KLA", "food_level_pct": 67.0,
            "water_temp": 24.5, "wifi_rssi": -62 }
    """
    serializer_class   = TelemetrySerializer
    permission_classes = [AllowAny]  # Device-Token checked manually below

    def create(self, request, *args, **kwargs):
        serial = request.data.get('device_serial', '')

        # Validate device token if provided (ESP32 path)
        device_token = request.META.get('HTTP_DEVICE_TOKEN', '')
        if device_token and not _verify_device_token(request, serial):
            return Response({'detail': 'Invalid Device-Token.'}, status=status.HTTP_401_UNAUTHORIZED)

        # If neither device token nor user auth, reject
        if not device_token and not request.user.is_authenticated:
            return Response({'detail': 'Authentication required.'}, status=status.HTTP_401_UNAUTHORIZED)

        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        tel = serializer.save()
        # Update device last_seen and pond food level
        try:
            device = DeviceInfo.objects.get(serial=tel.device_serial)
            device.updated_at = timezone.now()
            if tel.wifi_rssi is not None:
                device.wifi_rssi = tel.wifi_rssi
            device.save()
            pond = Pond.objects.get(name=device.pond_name)
            pond.food_percent = int(tel.food_level_pct)
            pond.is_online    = True
            if tel.water_temp is not None:
                pond.water_temp = tel.water_temp
            pond.save()
        except Exception:
            pass


# ── Device commands polling (called by ESP32) ─────────────────
@api_view(['GET'])
@permission_classes([AllowAny])
def device_poll_commands(request, serial):
    """
    GET /api/v1/devices/{serial}/poll/
    ESP32 calls this every 5 s to check for pending commands.
    Authenticates via Device-Token header.
    """
    if not _verify_device_token(request, serial):
        return Response({'detail': 'Invalid Device-Token.'}, status=status.HTTP_401_UNAUTHORIZED)

    # Update last_seen
    DeviceInfo.objects.filter(serial=serial).update(updated_at=timezone.now())
    Pond.objects.filter(feeder_serial=serial).update(is_online=True)

    cmds = DeviceCommand.objects.filter(
        device_serial=serial, status='pending'
    ).order_by('created_at')
    return Response(DeviceCommandSerializer(cmds, many=True).data)


# ── Command ACK (called by ESP32 after executing a command) ───
class DeviceCommandAckView(APIView):
    """
    POST /api/v1/commands/{id}/ack/
    Accepts both user Token auth and Device-Token header.
    """
    permission_classes = [AllowAny]

    def post(self, request, pk):
        # Allow device-token or user auth
        device_token = request.META.get('HTTP_DEVICE_TOKEN', '')
        if not device_token and not request.user.is_authenticated:
            return Response({'detail': 'Authentication required.'}, status=status.HTTP_401_UNAUTHORIZED)

        try:
            cmd = DeviceCommand.objects.get(pk=pk)
            # If device token provided, verify it matches the command's device
            if device_token and not _verify_device_token(request, cmd.device_serial):
                return Response({'detail': 'Invalid Device-Token.'}, status=status.HTTP_401_UNAUTHORIZED)
            cmd.status       = 'delivered'
            cmd.delivered_at = timezone.now()
            cmd.save()
            return Response({'detail': 'Acknowledged.'})
        except DeviceCommand.DoesNotExist:
            return Response({'detail': 'Command not found.'}, status=status.HTTP_404_NOT_FOUND)


# ── Export ────────────────────────────────────────────────────
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def export_logs(request):
    """GET /export/?serial=X&from=Y&to=Z&format=csv"""
    serial = request.query_params.get('serial', '')
    fmt    = request.query_params.get('format', 'csv').upper()
    # Stub: return metadata — real export handled by a Celery task
    logs = FeedLog.objects.filter(pond_name__icontains=serial).count()
    return Response({
        'serial': serial,
        'format': fmt,
        'record_count': logs,
        'status': 'export_queued',
        'message': f'{logs} records queued for {fmt} export. Download link sent to your email.',
    })
