from django.core.management.base import BaseCommand
from api.models import Device
import secrets

class Command(BaseCommand):
    help = 'Rotate device tokens. If serial is provided as argument, rotate only that device.'

    def add_arguments(self, parser):
        parser.add_argument('--serial', help='Device serial to rotate token for', required=False)

    def handle(self, *args, **options):
        serial = options.get('serial')
        qs = Device.objects.all() if not serial else Device.objects.filter(serial=serial)
        for d in qs:
            old = d.token
            d.token = secrets.token_hex(24)
            d.save()
            self.stdout.write(f'Rotated {d.serial}: {old} -> {d.token}')
        self.stdout.write('Done')
