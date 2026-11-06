import datetime
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.accounts.models import User
from apps.budgets.models import Budget
from apps.expenses.models import Expense
from apps.tasks.models import Task

class Command(BaseCommand):
    help = 'Seeds demo user accounts and initial budget/tasks for Duo.'

    def handle(self, *args, **options):
        self.stdout.write("Seeding demo accounts...")
        now = timezone.now()
        current_year = now.year
        current_month = now.month
        today = now.date()

        # 1. Create or update User 1: Alex Sharma
        alex, alex_created = User.objects.get_or_create(
            email='alex.sharma@duo.app',
            defaults={
                'name': 'Alex Sharma',
                'is_active': True,
            }
        )
        alex.name = 'Alex Sharma'
        alex.set_password('password123')
        alex.save()
        self.stdout.write(f"{'Created' if alex_created else 'Updated'} user: alex.sharma@duo.app (password: password123)")

        # 2. Create or update User 2: Priya Patel
        priya, priya_created = User.objects.get_or_create(
            email='priya.patel@duo.app',
            defaults={
                'name': 'Priya Patel',
                'is_active': True,
            }
        )
        priya.name = 'Priya Patel'
        priya.set_password('password123')
        priya.save()
        self.stdout.write(f"{'Created' if priya_created else 'Updated'} user: priya.patel@duo.app (password: password123)")

        # 3. Monthly Budget for Alex
        alex_budget, _ = Budget.objects.update_or_create(
            user=alex,
            year=current_year,
            month=current_month,
            defaults={
                'amount_limit': Decimal('35000.00'),
            }
        )
        self.stdout.write(f"Budget set for Alex ({current_month}/{current_year}): INR {alex_budget.amount_limit}")

        # 4. Monthly Budget for Priya
        priya_budget, _ = Budget.objects.update_or_create(
            user=priya,
            year=current_year,
            month=current_month,
            defaults={
                'amount_limit': Decimal('40000.00'),
            }
        )
        self.stdout.write(f"Budget set for Priya ({current_month}/{current_year}): INR {priya_budget.amount_limit}")

        # 5. Sample Personal Tasks for Alex
        Task.objects.get_or_create(
            creator=alex,
            title="Review personal monthly investments",
            defaults={
                'description': 'Review mutual fund SIPs and tax-saving accounts.',
                'category': 'Finance',
                'priority': 'HIGH',
                'status': 'PENDING',
                'due_date': today + datetime.timedelta(days=2),
                'has_reminder': True,
            }
        )
        Task.objects.get_or_create(
            creator=alex,
            title="Plan weekend grocery shopping",
            defaults={
                'description': 'Buy organic vegetables, almond milk, and pantry staples.',
                'category': 'Home',
                'priority': 'MEDIUM',
                'status': 'PENDING',
                'due_date': today + datetime.timedelta(days=1),
            }
        )

        # 6. Sample Personal Task for Priya
        Task.objects.get_or_create(
            creator=priya,
            title="Quarterly tax planning",
            defaults={
                'description': 'Review deduction limits and submit 80C declarations.',
                'category': 'Finance',
                'priority': 'HIGH',
                'status': 'PENDING',
                'due_date': today + datetime.timedelta(days=3),
            }
        )

        self.stdout.write(self.style.SUCCESS("Demo data seeding completed successfully!"))

