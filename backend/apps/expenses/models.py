from django.db import models
from django.conf import settings

class Expense(models.Model):
    CATEGORY_FOOD = 'Food'
    CATEGORY_BILLS = 'Bills'
    CATEGORY_SHOPPING = 'Shopping'
    CATEGORY_TRAVEL = 'Travel'
    CATEGORY_HEALTH = 'Health'
    CATEGORY_ENTERTAINMENT = 'Entertainment'
    CATEGORY_OTHER = 'Other'

    CATEGORY_CHOICES = [
        (CATEGORY_FOOD, 'Food'),
        (CATEGORY_BILLS, 'Bills'),
        (CATEGORY_SHOPPING, 'Shopping'),
        (CATEGORY_TRAVEL, 'Travel'),
        (CATEGORY_HEALTH, 'Health'),
        (CATEGORY_ENTERTAINMENT, 'Entertainment'),
        (CATEGORY_OTHER, 'Other'),
    ]

    PAYMENT_UPI = 'UPI'
    PAYMENT_CREDIT = 'Credit Card'
    PAYMENT_DEBIT = 'Debit Card'
    PAYMENT_CASH = 'Cash'
    PAYMENT_NETBANKING = 'Net Banking'

    PAYMENT_CHOICES = [
        (PAYMENT_UPI, 'UPI'),
        (PAYMENT_CREDIT, 'Credit Card'),
        (PAYMENT_DEBIT, 'Debit Card'),
        (PAYMENT_CASH, 'Cash'),
        (PAYMENT_NETBANKING, 'Net Banking'),
    ]

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='expenses'
    )
    title = models.CharField(max_length=150)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default=CATEGORY_OTHER, db_index=True)
    description = models.TextField(blank=True, default='')
    location = models.CharField(max_length=150, blank=True, default='')
    payment_method = models.CharField(max_length=50, choices=PAYMENT_CHOICES, default=PAYMENT_UPI)
    expense_date = models.DateField(db_index=True)
    receipt = models.FileField(upload_to='receipts/%Y/%m/', null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-expense_date', '-created_at']
        indexes = [
            models.Index(fields=['owner', 'expense_date']),
            models.Index(fields=['owner', 'category']),
        ]

    def __str__(self):
        return f"{self.title} - ₹{self.amount} ({self.owner.name})"
