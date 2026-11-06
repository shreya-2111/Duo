from django.db import models
from django.conf import settings

class Notification(models.Model):
    TYPE_BUDGET_WARNING = 'BUDGET_WARNING'
    TYPE_TASK_REMINDER = 'TASK_REMINDER'
    TYPE_GENERAL = 'GENERAL'

    TYPE_CHOICES = [
        (TYPE_BUDGET_WARNING, 'Budget Warning'),
        (TYPE_TASK_REMINDER, 'Task Reminder'),
        (TYPE_GENERAL, 'General'),
    ]

    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=30, choices=TYPE_CHOICES, default=TYPE_GENERAL)
    is_read = models.BooleanField(default=False, db_index=True)
    reference_id = models.CharField(max_length=100, blank=True, default='')

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', 'is_read', '-created_at']),
        ]

    def __str__(self):
        status = 'Read' if self.is_read else 'Unread'
        return f"{self.title} for {self.recipient.name} ({status})"

