from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import Task
from .serializers import TaskSerializer

class TaskListCreateView(generics.ListCreateAPIView):
    """
    List and create personal tasks for the authenticated user.
    Strictly isolated: only the task creator can access their tasks.
    Supports filtering by status, category, priority, date range (for Calendar view), and search.
    """
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        today = timezone.now().date()

        queryset = Task.objects.filter(creator=user)

        task_status = self.request.query_params.get('status')
        filter_type = self.request.query_params.get('filter')
        priority = self.request.query_params.get('priority')
        category = self.request.query_params.get('category')
        search = self.request.query_params.get('search')
        exact_due_date = self.request.query_params.get('due_date')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')

        # Status / Overdue Filter
        if task_status == 'OVERDUE' or filter_type == 'OVERDUE':
            queryset = queryset.filter(due_date__lt=today).exclude(status=Task.STATUS_COMPLETED)
        elif task_status:
            queryset = queryset.filter(status=task_status)

        # Date Filters
        if filter_type == 'TODAY':
            queryset = queryset.filter(due_date=today)
        elif filter_type == 'UPCOMING':
            queryset = queryset.filter(due_date__gt=today)

        # Calendar specific date filters
        if exact_due_date:
            queryset = queryset.filter(due_date=exact_due_date)
        if start_date:
            queryset = queryset.filter(due_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(due_date__lte=end_date)

        # Category Filter
        if category and category != 'All':
            queryset = queryset.filter(category=category)

        # Priority Filter
        if priority:
            queryset = queryset.filter(priority=priority)

        # Search Filter
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(description__icontains=search)
            )

        return queryset

    def perform_create(self, serializer):
        serializer.save(creator=self.request.user)

class TaskDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update, or delete a personal task.
    Strictly enforced: only the task owner can access or modify it.
    """
    serializer_class = TaskSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Task.objects.filter(creator=self.request.user)

class TaskToggleStatusView(APIView):
    """
    Toggle task between Completed, In Progress, and Pending.
    """
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        user = request.user
        task = get_object_or_404(Task.objects.filter(creator=user), pk=pk)

        new_status = request.data.get('status')
        if new_status in [Task.STATUS_PENDING, Task.STATUS_IN_PROGRESS, Task.STATUS_COMPLETED]:
            task.status = new_status
            if new_status == Task.STATUS_COMPLETED:
                task.mark_completed(True)
            else:
                task.mark_completed(False)
        else:
            is_comp = task.status == Task.STATUS_COMPLETED
            task.mark_completed(not is_comp)

        return Response(TaskSerializer(task, context={'request': request}).data)

class TaskSummaryView(APIView):
    """
    Returns task metrics for the authenticated user:
    Total, Pending, In Progress, Completed, Overdue, and Due Today counts.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        today = timezone.now().date()
        qs = Task.objects.filter(creator=user)

        return Response({
            'personal': {
                'total': qs.count(),
                'pending': qs.filter(status=Task.STATUS_PENDING).count(),
                'in_progress': qs.filter(status=Task.STATUS_IN_PROGRESS).count(),
                'completed': qs.filter(status=Task.STATUS_COMPLETED).count(),
                'overdue': qs.filter(due_date__lt=today).exclude(status=Task.STATUS_COMPLETED).count(),
                'today': qs.filter(due_date=today).exclude(status=Task.STATUS_COMPLETED).count(),
            },
            'counts': {
                'completed_total': qs.filter(status=Task.STATUS_COMPLETED).count(),
                'pending_total': qs.exclude(status=Task.STATUS_COMPLETED).count(),
                'today_total': qs.filter(due_date=today).exclude(status=Task.STATUS_COMPLETED).count(),
                'overdue_total': qs.filter(due_date__lt=today).exclude(status=Task.STATUS_COMPLETED).count(),
            }
        })
