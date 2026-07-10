from django.test import TestCase
from rest_framework.test import APIClient
from django.utils import timezone
import uuid
from api.models import Command, Device

class DeviceLifecycleTest(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_register_telemetry_command_pull_ack(self):
        # Register device
        resp = self.client.post('/api/devices/register/', {'serial': 'TST-001', 'name': 'Test Pond'}, format='json')
        self.assertIn(resp.status_code, (200,201))
        token = resp.data.get('token')
        self.assertIsNotNone(token)

        # Send telemetry with device token
        self.client.credentials(HTTP_DEVICE_TOKEN=token)
        telemetry = {
            'serial': 'TST-001',
            'pond_name': 'Test Pond',
            'hopper_percent': 88.5,
            'water_temp': 24.5,
            'ph': 7.1,
            'wifi_rssi': -40,
            'uptime': 12345,
            'timestamp': timezone.now().isoformat()
        }
        r = self.client.post('/api/telemetry/', telemetry, format='json')
        self.assertEqual(r.status_code, 200)

        # Post a device-scoped command anonymously (no user auth expected)
        self.client.credentials()  # clear client credentials
        cmd_id = str(uuid.uuid4())
        cmd_payload = {'id': cmd_id, 'command': 'feed', 'payload': {'amount_grams': 5}}
        post_resp = self.client.post('/api/commands/TST-001/', cmd_payload, format='json')
        self.assertEqual(post_resp.status_code, 201)
        self.assertIn('id', post_resp.data)

        # Pull commands as device
        self.client.credentials(HTTP_DEVICE_TOKEN=token)
        pull_resp = self.client.get('/api/commands/TST-001/pull/')
        self.assertEqual(pull_resp.status_code, 200)
        cmds = pull_resp.data
        self.assertTrue(any(c['id'] == cmd_id for c in cmds))

        # After pull, the command should be deleted from DB
        exists = Command.objects.filter(id=cmd_id).exists()
        self.assertFalse(exists)

        # Ack endpoint should accept ack (no-op server-side)
        ack_payload = {'id': cmd_id, 'status': 'done', 'acked_at': timezone.now().isoformat()}
        ack_resp = self.client.post('/api/commands/TST-001/ack/', ack_payload, format='json')
        self.assertEqual(ack_resp.status_code, 200)
        self.assertEqual(ack_resp.data.get('status'), 'acknowledged')
