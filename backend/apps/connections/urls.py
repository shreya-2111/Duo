from django.urls import path
from .views import DeprecatedConnectionView

urlpatterns = [
    path('current/', DeprecatedConnectionView.as_view(), name='connection_deprecated_current'),
    path('generate-code/', DeprecatedConnectionView.as_view(), name='connection_deprecated_generate'),
    path('preview-invite/', DeprecatedConnectionView.as_view(), name='connection_deprecated_preview'),
    path('redeem-invite/', DeprecatedConnectionView.as_view(), name='connection_deprecated_redeem'),
    path('disconnect/', DeprecatedConnectionView.as_view(), name='connection_deprecated_disconnect'),
    path('spaces/', DeprecatedConnectionView.as_view(), name='connection_deprecated_spaces'),
]
