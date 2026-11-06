from django.urls import path
from .views import (
    ExpenseListCreateView,
    ExpenseDetailView,
    ExpenseMonthlySummaryView,
)

urlpatterns = [
    path('', ExpenseListCreateView.as_view(), name='expense_list_create'),
    path('summary/', ExpenseMonthlySummaryView.as_view(), name='expense_monthly_summary'),
    path('<int:pk>/', ExpenseDetailView.as_view(), name='expense_detail'),
]
