from django.urls import path
from .views import (
    BudgetListCreateView,
    CurrentMonthBudgetView,
    BudgetDetailView,
)

urlpatterns = [
    path('', BudgetListCreateView.as_view(), name='budget_list_create'),
    path('current/', CurrentMonthBudgetView.as_view(), name='budget_current'),
    path('<int:pk>/', BudgetDetailView.as_view(), name='budget_detail'),
]
