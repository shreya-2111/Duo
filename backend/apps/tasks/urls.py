from django.urls import path
from .views import (
    TaskListCreateView,
    TaskDetailView,
    TaskToggleStatusView,
    TaskSummaryView,
)

urlpatterns = [
    path('', TaskListCreateView.as_view(), name='task_list_create'),
    path('summary/', TaskSummaryView.as_view(), name='task_summary'),
    path('<int:pk>/', TaskDetailView.as_view(), name='task_detail'),
    path('<int:pk>/toggle/', TaskToggleStatusView.as_view(), name='task_toggle'),
]
