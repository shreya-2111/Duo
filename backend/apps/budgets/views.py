from decimal import Decimal
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Sum
from .models import Budget
from .serializers import BudgetSerializer
# pyrefly: ignore[missing-import]
from apps.accounts.permissions import IsOwner
# pyrefly: ignore[missing-import]
from apps.expenses.models import Expense

class BudgetListCreateView(generics.ListCreateAPIView):
    serializer_class = BudgetSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Strict user-level isolation
        return Budget.objects.filter(user=self.request.user)

class CurrentMonthBudgetView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        now = timezone.now()
        year = int(request.query_params.get('year', now.year))
        month = int(request.query_params.get('month', now.month))

        budget = Budget.objects.filter(user=request.user, year=year, month=month).first()
        if not budget:
            spent = Expense.objects.filter(
                owner=request.user,
                expense_date__year=year,
                expense_date__month=month
            ).aggregate(s=Sum('amount'))['s'] or Decimal('0.00')

            return Response({
                'configured': False,
                'month': month,
                'year': year,
                'amount_limit': 0.0,
                'summary': {
                    'budget_id': None,
                    'month': month,
                    'year': year,
                    'amount_limit': 0.0,
                    'total_spent': float(spent),
                    'remaining': 0.0,
                    'percentage_used': 0.0,
                    'alert_level': 'NO_BUDGET_SET',
                    'alert_message': 'No monthly budget configured yet.',
                }
            })

        return Response({
            'configured': True,
            'budget': BudgetSerializer(budget, context={'request': request}).data
        })

    def post(self, request):
        now = timezone.now()
        month = int(request.data.get('month', now.month))
        year = int(request.data.get('year', now.year))
        raw_limit = request.data.get('amount_limit')

        if raw_limit is None or float(raw_limit) <= 0:
            return Response(
                {'error': 'A valid positive budget limit is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        amount_limit = Decimal(str(raw_limit))

        budget, _ = Budget.objects.update_or_create(
            user=request.user,
            month=month,
            year=year,
            defaults={'amount_limit': amount_limit}
        )

        return Response(BudgetSerializer(budget, context={'request': request}).data, status=status.HTTP_200_OK)

class BudgetDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = BudgetSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Budget.objects.filter(user=self.request.user)
