from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import status
from .models import Pond, Command
from .serializers import CommandSerializer
import uuid

@api_view(['POST'])
def trigger_feed(request, pond_id):
    try:
        pond = Pond.objects.get(id=pond_id)
    except Pond.DoesNotExist:
        return Response({'detail':'not found'}, status=status.HTTP_404_NOT_FOUND)
    amount = request.data.get('amount_grams')
    amount_use = amount or (pond.schedules.first().amount_grams if pond.schedules.exists() else 5.0)
    # create command
    cmd = Command(id=str(uuid.uuid4()), serial=pond.serial, command='feed', payload={'amount_grams': amount_use})
    cmd.save()
    # optimistic feed log (will be confirmed when device acks in production)
    from .models import FeedLog
    from django.utils import timezone
    fl = FeedLog(id=str(uuid.uuid4()), pond=pond, serial=pond.serial, amount_grams=amount_use, timestamp=timezone.now())
    fl.save()
    return Response({'status':'queued','id':cmd.id}, status=status.HTTP_201_CREATED)
