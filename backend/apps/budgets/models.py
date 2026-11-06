from decimal import Decimal
from django.db import models
from django.conf import settings
from django.db.models import Sum

class Budget(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='budgets'
    )
    month = models.PositiveSmallIntegerField()  # 1 to 12
    year = models.PositiveSmallIntegerField()   # e.g. 2026
    amount_limit = models.DecimalField(max_digits=12, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'month', 'year'],
                name='unique_user_month_year_budget'
            )
        ]
        indexes = [
            models.Index(fields=['user', 'year', 'month']),
        ]
        ordering = ['-year', '-month']

    def __str__(self):
        return f"{self.user.name}'s Budget {self.month}/{self.year}: ₹{self.amount_limit}"

    def get_summary(self):
        # pyrefly: ignore[missing-import]
        from apps.expenses.models import Expense

        total_spent = Expense.objects.filter(
            owner=self.user,
            expense_date__year=self.year,
            expense_date__month=self.month
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')

        limit = Decimal(str(self.amount_limit))
        percent = (total_spent / limit * Decimal('100.0')) if limit > Decimal('0.00') else Decimal('0.0')

        if percent >= Decimal('100.0'):
            alert_level = 'OVER_BUDGET' if percent > Decimal('100.0') else 'REACHED_100'
            alert_message = (
                f"Budget exceeded by ₹{(total_spent - limit):.2f}!"
                if percent > Decimal('100.0')
                else "100% of your monthly budget reached!"
            )
        elif percent >= Decimal('80.0'):
            alert_level = 'WARNING_80'
            alert_message = f"Budget Alert: You have used {percent:.1f}% of your monthly allowance."
        else:
            alert_level = 'SAFE'
            alert_message = f"On track: {percent:.1f}% used."

        return {
            'budget_id': self.id,
            'month': self.month,
            'year': self.year,
            'amount_limit': float(limit),
            'total_spent': float(total_spent),
            'remaining': float(max(Decimal('0.00'), limit - total_spent)),
            'over_spent': float(max(Decimal('0.00'), total_spent - limit)),
            'raw_remaining': float(limit - total_spent),
            'percentage_used': round(float(percent), 1),
            'alert_level': alert_level,
            'alert_message': alert_message,
        }
