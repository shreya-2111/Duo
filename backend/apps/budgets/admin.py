from django.contrib import admin
from .models import Budget

@admin.register(Budget)
class BudgetAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'month', 'year', 'amount_limit', 'created_at')
    list_filter = ('year', 'month')
    search_fields = ('user__name', 'user__email')
