from django.contrib import admin
from .models import Task

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'creator', 'priority', 'status', 'due_date', 'has_reminder', 'repeat_type', 'created_at')
    list_filter = ('status', 'priority', 'repeat_type', 'has_reminder', 'category')
    search_fields = ('title', 'creator__email', 'creator__name')

