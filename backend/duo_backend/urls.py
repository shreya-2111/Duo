from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from django.db import connection

def api_root(request):
    return JsonResponse({
        "project": "Duo Backend API",
        "tagline": "Money Managed. Tasks Shared.",
        "status": "online",
        "version": "2.0.0",
        "health": "/api/health/",
        "endpoints": {
            "admin": "/admin/",
            "accounts": "/api/accounts/",
            "dashboard": "/api/accounts/dashboard/",
            "budgets": "/api/budgets/",
            "expenses": "/api/expenses/",
            "tasks": "/api/tasks/",
            "notifications": "/api/notifications/",
        }
    })

def health_check(request):
    db_ok = True
    db_error = None
    try:
        connection.ensure_connection()
    except Exception as e:
        db_ok = False
        db_error = str(e)

    status_code = 200 if db_ok else 503
    return JsonResponse({
        "status": "healthy" if db_ok else "unhealthy",
        "database": "connected" if db_ok else "disconnected",
        "db_error": db_error,
        "service": "duo-backend",
        "version": "2.0.0",
    }, status=status_code)

urlpatterns = [
    path('', api_root, name='api_root'),
    path('api/health/', health_check, name='health_check'),
    path('admin/', admin.site.urls),
    path('api/accounts/', include('apps.accounts.urls')),
    path('api/connections/', include('apps.connections.urls')),
    path('api/budgets/', include('apps.budgets.urls')),
    path('api/expenses/', include('apps.expenses.urls')),
    path('api/tasks/', include('apps.tasks.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
