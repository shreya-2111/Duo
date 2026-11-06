from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from django.utils import timezone
from django.db import models
from django.db.models import Sum
from django.contrib.auth.tokens import default_token_generator
from .models import User
from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    UserSerializer,
    UserProfileUpdateSerializer,
    ForgotPasswordSerializer,
    ResetPasswordSerializer,
)
# pyrefly: ignore[missing-import]
from apps.budgets.models import Budget
# pyrefly: ignore[missing-import]
from apps.expenses.models import Expense
# pyrefly: ignore[missing-import]
from apps.expenses.serializers import ExpenseSerializer
# pyrefly: ignore[missing-import]
from apps.tasks.models import Task
# pyrefly: ignore[missing-import]
from apps.tasks.serializers import TaskSerializer
# pyrefly: ignore[missing-import]
from apps.notifications.models import Notification

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Account created successfully.',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        }, status=status.HTTP_201_CREATED)

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Logged in successfully.',
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        })

class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if not refresh_token:
                return Response({'error': 'Refresh token is required.'}, status=status.HTTP_400_BAD_REQUEST)
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Logged out successfully.'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'error': 'Invalid or expired token.'}, status=status.HTTP_400_BAD_REQUEST)

class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UserProfileUpdateSerializer
        return UserSerializer

class ForgotPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        try:
            user = User.objects.get(email__iexact=email)
            token = default_token_generator.make_token(user)
            return Response({
                'message': 'Password reset token generated successfully.',
                'email': user.email,
                'reset_token': token,
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({
                'message': 'If an account exists with this email, a reset token has been issued.',
            }, status=status.HTTP_200_OK)

class ResetPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        token = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']

        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            return Response({'error': 'Invalid email or reset token.'}, status=status.HTTP_400_BAD_REQUEST)

        if not default_token_generator.check_token(user, token):
            return Response({'error': 'Invalid or expired reset token.'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        return Response({'message': 'Password has been reset successfully. Please log in with your new password.'}, status=status.HTTP_200_OK)

class DashboardOverviewView(APIView):
    """
    Main unified personal dashboard overview API.
    Returns:
    - User profile
    - Current month's budget & spending summary
    - Top recent 5 private expenses
    - Today's pending personal tasks
    - Upcoming personal tasks
    - Task statistics (pending, completed, today, upcoming)
    - Monthly spending analytics (category-wise breakdown)
    - Unread notification count
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        now = timezone.now()

        # 1. Budget & Spending Summary
        budget = Budget.objects.filter(user=user, year=now.year, month=now.month).first()
        budget_summary = budget.get_summary() if budget else {
            'budget_id': None,
            'month': now.month,
            'year': now.year,
            'amount_limit': 0.0,
            'total_spent': float(
                Expense.objects.filter(owner=user, expense_date__year=now.year, expense_date__month=now.month)
                .aggregate(s=models.Sum('amount'))['s'] or 0.0
            ),
            'remaining': 0.0,
            'percentage_used': 0.0,
            'alert_level': 'NO_BUDGET_SET',
            'alert_message': 'No monthly budget configured yet.',
        }

        # 2. Recent Expenses (Strictly owned by user)
        recent_expenses = Expense.objects.filter(owner=user).order_by('-expense_date', '-created_at')[:5]

        # 3. Monthly Spending Analytics (Category breakdown)
        monthly_expenses = Expense.objects.filter(owner=user, expense_date__year=now.year, expense_date__month=now.month)
        month_total = float(monthly_expenses.aggregate(s=models.Sum('amount'))['s'] or 0.0)
        category_breakdown = []
        if month_total > 0:
            category_totals = monthly_expenses.values('category').annotate(cat_sum=Sum('amount')).order_by('-cat_sum')
            for item in category_totals:
                c_sum = float(item['cat_sum'] or 0.0)
                category_breakdown.append({
                    'category': item['category'],
                    'total': c_sum,
                    'percentage': round((c_sum / month_total) * 100, 1),
                })

        # 4. Tasks Queries (Strictly personal to user)
        today = now.date()
        user_tasks = Task.objects.filter(creator=user)

        today_tasks = user_tasks.filter(
            due_date=today
        ).exclude(status=Task.STATUS_COMPLETED).order_by('-priority', 'due_date')[:6]

        upcoming_tasks = user_tasks.filter(
            due_date__gt=today
        ).exclude(status=Task.STATUS_COMPLETED).order_by('due_date', '-priority')[:6]

        completed_task_count = user_tasks.filter(status=Task.STATUS_COMPLETED).count()
        pending_task_count = user_tasks.exclude(status=Task.STATUS_COMPLETED).count()
        recent_tasks = user_tasks.exclude(status=Task.STATUS_COMPLETED).order_by('due_date', '-priority')[:5]

        # 5. Unread notifications count
        unread_notifications = Notification.objects.filter(recipient=user, is_read=False).count()

        return Response({
            'user': UserSerializer(user).data,
            'budget_summary': budget_summary,
            'recent_expenses': ExpenseSerializer(recent_expenses, many=True).data,
            'spending_analytics': category_breakdown,
            'today_tasks': TaskSerializer(today_tasks, many=True).data,
            'upcoming_tasks': TaskSerializer(upcoming_tasks, many=True).data,
            'personal_tasks': TaskSerializer(recent_tasks, many=True).data,
            'shared_tasks': [],
            'task_stats': {
                'completed_count': completed_task_count,
                'pending_count': pending_task_count,
                'today_count': today_tasks.count(),
                'upcoming_count': upcoming_tasks.count(),
            },
            'shared_task_summary': {
                'total_shared': 0,
                'pending_shared': 0,
                'completed_shared': 0,
                'assigned_to_me': 0,
                'assigned_to_partner': 0,
            },
            'unread_notifications_count': unread_notifications,
            'active_spaces_count': 0,
        })

