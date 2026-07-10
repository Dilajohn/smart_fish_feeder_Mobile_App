from django.core.management.base import BaseCommand
from django.utils import timezone
import time
from api.models import FeedSchedule, Pond, Command, FeedLog
import uuid

class Command(BaseCommand):
    help = 'Run a simple scheduler that converts schedules into commands'

    def handle(self, *args, **options):
        self.stdout.write('Scheduler started (ctrl-c to stop)')
        try:
            while True:
                now = timezone.now()
                # naive: match time string HH:MM
                schedules = FeedSchedule.objects.all()
                for s in schedules:
                    if s.time:
                        try:
                            hhmm = s.time.strip()
                            if hhmm == now.strftime('%H:%M'):
                                pond = s.pond
                                cmd = CommandModel(id=str(uuid.uuid4()), serial=pond.serial, command='feed', payload={'amount_grams': s.amount_grams})
                                cmd.save()
                                # Also create a feed log (optimistic)
                                fl = FeedLog(id=str(uuid.uuid4()), pond=pond, serial=pond.serial, amount_grams=s.amount_grams, timestamp=now)
                                fl.save()
                                self.stdout.write(f'Triggered feed for pond {pond.id} at {now}')
                        except Exception as e:
                            self.stderr.write(str(e))
                time.sleep(30)
        except KeyboardInterrupt:
            self.stdout.write('Scheduler stopped')

# Avoid name collision with local CommandModel
from api.models import Command as CommandModel
