from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView,
    LoginView,
    LogoutView,
    UserProfileView,
    DashboardOverviewView,
    ForgotPasswordView,
    ResetPasswordView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='account_register'),
    path('login/', LoginView.as_view(), name='account_login'),
    path('logout/', LogoutView.as_view(), name='account_logout'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='account_forgot_password'),
    path('reset-password/', ResetPasswordView.as_view(), name='account_reset_password'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', UserProfileView.as_view(), name='account_profile'),
    path('dashboard/', DashboardOverviewView.as_view(), name='account_dashboard'),
]


