from celery import shared_task
from django.utils import timezone
from .models import FeedSchedule, Command, FeedLog
import uuid

@shared_task
def run_scheduled_feeds():
    # Simple task: find schedules for current time and create commands + feed logs
    now = timezone.now()
    hhmm = now.strftime('%H:%M')
    schedules = FeedSchedule.objects.all()
    created = 0
    for s in schedules:
        if s.time and s.time.strip() == hhmm:
            pond = s.pond
            cmd = Command(id=str(uuid.uuid4()), serial=pond.serial, command='feed', payload={'amount_grams': s.amount_grams})
            cmd.save()
            fl = FeedLog(id=str(uuid.uuid4()), pond=pond, serial=pond.serial, amount_grams=s.amount_grams, timestamp=now)
            fl.save()
            created += 1
    return {'created': created}
