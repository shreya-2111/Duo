from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Budget
from apps.expenses.models import Expense

User = get_user_model()

class BudgetAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(email='buser@duo.app', name='Budget User', password='password123')
        self.other_user = User.objects.create_user(email='other@duo.app', name='Other User', password='password123')

    def test_create_and_update_monthly_budget(self):
        self.client.force_authenticate(user=self.user)
        # Create budget
        res = self.client.post(reverse('budget_list_create'), {
            'month': 11,
            'year': 2026,
            'amount_limit': '35000.00'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Budget.objects.filter(user=self.user).count(), 1)

        # Update budget for same month/year replaces/updates limit (unique constraint)
        res2 = self.client.post(reverse('budget_list_create'), {
            'month': 11,
            'year': 2026,
            'amount_limit': '40000.00'
        })
        self.assertEqual(res2.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Budget.objects.filter(user=self.user).count(), 1)
        self.assertEqual(Budget.objects.get(user=self.user, month=11, year=2026).amount_limit, Decimal('40000.00'))

    def test_budget_privacy(self):
        # User 1 sets budget
        b = Budget.objects.create(user=self.user, month=11, year=2026, amount_limit=Decimal('20000.00'))

        # User 2 cannot view user 1's budget (Requirement 5)
        self.client.force_authenticate(user=self.other_user)
        res = self.client.get(reverse('budget_detail', kwargs={'pk': b.id}))
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_budget_alert_thresholds(self):
        budget = Budget.objects.create(user=self.user, month=11, year=2026, amount_limit=Decimal('10000.00'))

        # Spent 75% -> SAFE
        Expense.objects.create(
            owner=self.user,
            title='Rent portion',
            amount=Decimal('7500.00'),
            expense_date='2026-11-02'
        )
        summary = budget.get_summary()
        self.assertEqual(summary['alert_level'], 'SAFE')

        # Add more to reach 85% -> WARNING_80
        Expense.objects.create(
            owner=self.user,
            title='Groceries',
            amount=Decimal('1000.00'),
            expense_date='2026-11-03'
        )
        summary2 = budget.get_summary()
        self.assertEqual(summary2['alert_level'], 'WARNING_80')

        # Add exactly enough to reach 100% -> REACHED_100
        Expense.objects.create(
            owner=self.user,
            title='Target Exact',
            amount=Decimal('1500.00'),
            expense_date='2026-11-03'
        )
        summary_exact = budget.get_summary()
        self.assertEqual(summary_exact['alert_level'], 'REACHED_100')
        self.assertEqual(summary_exact['percentage_used'], 100.0)
        self.assertEqual(summary_exact['remaining'], 0.0)

        # Add more to exceed 100% -> OVER_BUDGET
        Expense.objects.create(
            owner=self.user,
            title='Weekend Trip',
            amount=Decimal('500.00'),
            expense_date='2026-11-04'
        )
        summary3 = budget.get_summary()
        self.assertEqual(summary3['alert_level'], 'OVER_BUDGET')
        self.assertEqual(summary3['over_spent'], 500.0)

