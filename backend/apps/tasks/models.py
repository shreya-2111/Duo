from django.db import models
from django.conf import settings
from django.utils import timezone

class Task(models.Model):
    PRIORITY_HIGH = 'HIGH'
    PRIORITY_MEDIUM = 'MEDIUM'
    PRIORITY_LOW = 'LOW'
    PRIORITY_CHOICES = [
        (PRIORITY_HIGH, 'High'),
        (PRIORITY_MEDIUM, 'Medium'),
        (PRIORITY_LOW, 'Low'),
    ]

    STATUS_PENDING = 'PENDING'
    STATUS_IN_PROGRESS = 'IN_PROGRESS'
    STATUS_COMPLETED = 'COMPLETED'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_IN_PROGRESS, 'In Progress'),
        (STATUS_COMPLETED, 'Completed'),
    ]

    REPEAT_NONE = 'NONE'
    REPEAT_DAILY = 'DAILY'
    REPEAT_WEEKLY = 'WEEKLY'
    REPEAT_MONTHLY = 'MONTHLY'
    REPEAT_CHOICES = [
        (REPEAT_NONE, 'None'),
        (REPEAT_DAILY, 'Daily'),
        (REPEAT_WEEKLY, 'Weekly'),
        (REPEAT_MONTHLY, 'Monthly'),
    ]

    # Every task strictly belongs to its authenticated owner
    creator = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='tasks'
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    category = models.CharField(max_length=50, blank=True, default='General', db_index=True)
    priority = models.CharField(max_length=15, choices=PRIORITY_CHOICES, default=PRIORITY_MEDIUM)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING, db_index=True)
    due_date = models.DateField(null=True, blank=True, db_index=True)
    due_time = models.TimeField(null=True, blank=True)
    repeat_type = models.CharField(max_length=15, choices=REPEAT_CHOICES, default=REPEAT_NONE)
    has_reminder = models.BooleanField(default=False)
    reminder_time = models.TimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['status', 'due_date', '-priority', '-created_at']
        indexes = [
            models.Index(fields=['creator', 'status', 'due_date']),
            models.Index(fields=['creator', 'category']),
        ]

    def __str__(self):
        return f"{self.title} ({self.status}) for {self.creator.name}"

    def mark_completed(self, is_completed=True):
        if is_completed:
            self.status = self.STATUS_COMPLETED
            self.completed_at = timezone.now()
        else:
            self.status = self.STATUS_PENDING
            self.completed_at = None
        self.save()
