from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Expense
from apps.budgets.models import Budget

User = get_user_model()

class ExpenseAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(email='euser@duo.app', name='Expense User', password='password123')
        self.other_user = User.objects.create_user(email='partner@duo.app', name='Partner User', password='password123')

    def test_create_private_expense(self):
        self.client.force_authenticate(user=self.user)
        res = self.client.post(reverse('expense_list_create'), {
            'title': 'Dinner at Toit',
            'amount': '1850.50',
            'category': 'Food',
            'description': 'Craft beverages and pizza',
            'location': 'Toit, Indiranagar',
            'payment_method': 'UPI',
            'expense_date': '2026-11-04'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        expense = Expense.objects.first()
        # Verify ownership set from auth user (Requirement 5)
        self.assertEqual(expense.owner, self.user)
        self.assertEqual(expense.amount, Decimal('1850.50'))

    def test_never_trust_client_supplied_owner(self):
        # Pass a spoofed owner_id or user_id in payload
        self.client.force_authenticate(user=self.user)
        res = self.client.post(reverse('expense_list_create'), {
            'owner': self.other_user.id,
            'title': 'Spoofed Expense',
            'amount': '500.00',
            'category': 'Shopping',
            'payment_method': 'Cash',
            'expense_date': '2026-11-04'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        expense = Expense.objects.get(title='Spoofed Expense')
        # Authenticated user is enforced!
        self.assertEqual(expense.owner, self.user)

    def test_expense_privacy_isolation(self):
        # User 1 creates an expense
        e1 = Expense.objects.create(
            owner=self.user,
            title='Private Gadget',
            amount=Decimal('5000.00'),
            category='Shopping',
            expense_date='2026-11-04'
        )

        # User 2 lists expenses -> should not see User 1's expense
        self.client.force_authenticate(user=self.other_user)
        res = self.client.get(reverse('expense_list_create'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 0)

        # User 2 attempts to retrieve User 1's expense by ID -> 404
        detail_res = self.client.get(reverse('expense_detail', kwargs={'pk': e1.id}))
        self.assertEqual(detail_res.status_code, status.HTTP_404_NOT_FOUND)

    def test_expense_monthly_summary(self):
        self.client.force_authenticate(user=self.user)
        Budget.objects.create(user=self.user, month=11, year=2026, amount_limit=Decimal('20000.00'))
        Expense.objects.create(owner=self.user, title='Groceries', amount=Decimal('3500.00'), category='Food', expense_date='2026-11-02')
        Expense.objects.create(owner=self.user, title='Electricity', amount=Decimal('1500.00'), category='Bills', expense_date='2026-11-03')

        res = self.client.get(reverse('expense_monthly_summary') + '?month=11&year=2026')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['total_spent'], 5000.00)
        self.assertEqual(len(res.data['categories']), 2)
        self.assertIn('monthly_comparison', res.data)

    def test_expense_update_and_delete(self):
        self.client.force_authenticate(user=self.user)
        exp = Expense.objects.create(
            owner=self.user,
            title='Old Title',
            amount=Decimal('450.00'),
            category='Food',
            expense_date='2026-11-01'
        )

        # Update expense
        update_res = self.client.patch(
            reverse('expense_detail', kwargs={'pk': exp.id}),
            {'title': 'New Updated Title', 'amount': '550.00'}
        )
        self.assertEqual(update_res.status_code, status.HTTP_200_OK)
        exp.refresh_from_db()
        self.assertEqual(exp.title, 'New Updated Title')
        self.assertEqual(exp.amount, Decimal('550.00'))

        # Delete expense
        del_res = self.client.delete(reverse('expense_detail', kwargs={'pk': exp.id}))
        self.assertEqual(del_res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Expense.objects.filter(id=exp.id).exists())

    def test_filter_by_category_and_date_range(self):
        self.client.force_authenticate(user=self.user)
        Expense.objects.create(owner=self.user, title='Oct Item', amount=Decimal('100.00'), category='Food', expense_date='2026-10-15')
        Expense.objects.create(owner=self.user, title='Nov Food', amount=Decimal('200.00'), category='Food', expense_date='2026-11-02')
        Expense.objects.create(owner=self.user, title='Nov Bills', amount=Decimal('300.00'), category='Bills', expense_date='2026-11-05')

        # Filter by category Food
        res = self.client.get(reverse('expense_list_create') + '?category=Food')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 2)

        # Filter by date range (Nov 1 to Nov 4)
        res_date = self.client.get(reverse('expense_list_create') + '?start_date=2026-11-01&end_date=2026-11-04')
        self.assertEqual(res_date.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res_date.data), 1)
        self.assertEqual(res_date.data[0]['title'], 'Nov Food')

    def test_continue_accepting_expenses_when_over_budget(self):
        self.client.force_authenticate(user=self.user)
        Budget.objects.create(user=self.user, month=11, year=2026, amount_limit=Decimal('1000.00'))

        # Spend 900
        Expense.objects.create(owner=self.user, title='Near Limit', amount=Decimal('900.00'), category='Food', expense_date='2026-11-01')

        # Spend 500 more -> total 1400 (> 1000)
        res = self.client.post(reverse('expense_list_create'), {
            'title': 'Over Budget Expense',
            'amount': '500.00',
            'category': 'Entertainment',
            'expense_date': '2026-11-02'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['budget_status']['alert_level'], 'OVER_BUDGET')
        self.assertEqual(res.data['budget_status']['total_spent'], 1400.0)
        self.assertEqual(res.data['budget_status']['over_spent'], 400.0)

