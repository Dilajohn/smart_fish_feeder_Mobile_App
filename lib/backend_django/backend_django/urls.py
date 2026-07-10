from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from rest_framework.schemas import get_schema_view
from rest_framework.authtoken.views import obtain_auth_token

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
    path('health/', lambda request: JsonResponse({'status': 'ok'})),
    path('api/schema/', get_schema_view(title='Smart Fish Feeder API')),
    path('api-token-auth/', obtain_auth_token),
    path('api-auth/', include('rest_framework.urls')),
]
