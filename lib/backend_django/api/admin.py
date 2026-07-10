from django.contrib import admin
from .models import Pond, FeedSchedule, FeedLog, Command

admin.site.register(Pond)
admin.site.register(FeedSchedule)
admin.site.register(FeedLog)
admin.site.register(Command)
