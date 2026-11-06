from decimal import Decimal
from rest_framework import generics, permissions, status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum, Count, Q
from django.utils import timezone
from .models import Expense
from .serializers import ExpenseSerializer
# pyrefly: ignore[missing-import]
from apps.accounts.permissions import IsOwner
# pyrefly: ignore[missing-import]
from apps.budgets.models import Budget
# pyrefly: ignore[missing-import]
from apps.notifications.models import Notification

class ExpenseListCreateView(generics.ListCreateAPIView):
    serializer_class = ExpenseSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        # Requirement 5 & 9: Enforce queryset filtering strictly for owner
        queryset = Expense.objects.filter(owner=self.request.user)

        month = self.request.query_params.get('month')
        year = self.request.query_params.get('year')
        category = self.request.query_params.get('category')
        search = self.request.query_params.get('search')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')

        if month and year:
            queryset = queryset.filter(expense_date__year=year, expense_date__month=month)
        elif year:
            queryset = queryset.filter(expense_date__year=year)

        if start_date:
            queryset = queryset.filter(expense_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(expense_date__lte=end_date)

        if category and category != 'All':
            queryset = queryset.filter(category=category)

        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(location__icontains=search) |
                Q(description__icontains=search)
            )

        return queryset

    def create(self, request, *args, **kwargs):
        # Requirement 5: Set ownership from authenticated user
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        expense = serializer.save(owner=request.user)

        # Check monthly budget alert status (Requirement 4 & non-blocking alerts)
        budget = Budget.objects.filter(
            user=request.user,
            year=expense.expense_date.year,
            month=expense.expense_date.month
        ).first()

        budget_summary = budget.get_summary() if budget else None

        # Create in-app notification if budget alert threshold crossed
        if budget_summary and budget_summary['alert_level'] in ['WARNING_80', 'REACHED_100', 'OVER_BUDGET']:
            Notification.objects.create(
                recipient=request.user,
                title="Monthly Budget Alert",
                message=budget_summary['alert_message'],
                notification_type=Notification.TYPE_BUDGET_WARNING,
                reference_id=str(expense.id)
            )

        headers = self.get_success_headers(serializer.data)
        return Response({
            'message': 'Expense recorded successfully.',
            'expense': serializer.data,
            'budget_status': budget_summary,
        }, status=status.HTTP_201_CREATED, headers=headers)

class ExpenseDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ExpenseSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwner]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_queryset(self):
        return Expense.objects.filter(owner=self.request.user)

class ExpenseMonthlySummaryView(APIView):
    """
    Requirement 8: Monthly expense summary API with category and payment method breakdowns,
    and monthly comparisons.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        now = timezone.now()
        year = int(request.query_params.get('year', now.year))
        month = int(request.query_params.get('month', now.month))

        user_expenses = Expense.objects.filter(
            owner=request.user,
            expense_date__year=year,
            expense_date__month=month
        )

        total_spent = user_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        transaction_count = user_expenses.count()

        # Category breakdown
        category_breakdown = (
            user_expenses.values('category')
            .annotate(total=Sum('amount'), count=Count('id'))
            .order_by('-total')
        )

        # Payment method breakdown
        payment_breakdown = (
            user_expenses.values('payment_method')
            .annotate(total=Sum('amount'), count=Count('id'))
            .order_by('-total')
        )

        # Daily average
        days_in_month = now.day if (year == now.year and month == now.month) else 30
        daily_average = float(total_spent) / max(1, days_in_month)

        # Budget comparison
        budget = Budget.objects.filter(user=request.user, year=year, month=month).first()
        budget_summary = budget.get_summary() if budget else {
            'budget_id': None,
            'month': month,
            'year': year,
            'amount_limit': 0.0,
            'total_spent': float(total_spent),
            'remaining': 0.0,
            'over_spent': 0.0,
            'raw_remaining': 0.0,
            'percentage_used': 0.0,
            'alert_level': 'NO_BUDGET_SET',
            'alert_message': 'No monthly budget configured yet.',
        }

        # Monthly comparison with previous month
        prev_month = 12 if month == 1 else month - 1
        prev_year = year - 1 if month == 1 else year
        prev_expenses = Expense.objects.filter(
            owner=request.user,
            expense_date__year=prev_year,
            expense_date__month=prev_month
        )
        prev_spent = prev_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        diff = total_spent - prev_spent
        change_percentage = round((float(diff) / float(prev_spent) * 100), 1) if prev_spent > Decimal('0.00') else None

        return Response({
            'year': year,
            'month': month,
            'currency': 'INR',
            'symbol': '₹',
            'total_spent': float(total_spent),
            'transaction_count': transaction_count,
            'daily_average': round(daily_average, 2),
            'monthly_comparison': {
                'previous_month': prev_month,
                'previous_year': prev_year,
                'previous_spent': float(prev_spent),
                'difference': float(diff),
                'change_percentage': change_percentage,
                'trend': 'UP' if diff > Decimal('0.00') else ('DOWN' if diff < Decimal('0.00') else 'SAME'),
            },
            'categories': [
                {
                    'category': item['category'],
                    'total': float(item['total']),
                    'count': item['count'],
                    'percentage': round((float(item['total']) / float(total_spent) * 100), 1) if total_spent > 0 else 0.0
                }
                for item in category_breakdown
            ],
            'payment_methods': [
                {
                    'payment_method': item['payment_method'],
                    'total': float(item['total']),
                    'count': item['count']
                }
                for item in payment_breakdown
            ],
            'budget': budget_summary,
        })
