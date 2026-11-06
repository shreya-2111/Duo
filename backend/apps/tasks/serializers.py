from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Task
# pyrefly: ignore[missing-import]
from apps.accounts.serializers import UserSerializer

User = get_user_model()

class TaskSerializer(serializers.ModelSerializer):
    creator_details = UserSerializer(source='creator', read_only=True)
    is_done = serializers.SerializerMethodField()
    is_overdue = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'id', 'title', 'description', 'category', 'priority',
            'status', 'is_done', 'is_overdue', 'due_date', 'due_time',
            'repeat_type', 'has_reminder', 'reminder_time',
            'creator', 'creator_details', 'completed_at',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'creator', 'creator_details', 'completed_at', 'created_at', 'updated_at']

    def get_is_done(self, obj):
        return obj.status == Task.STATUS_COMPLETED

    def get_is_overdue(self, obj):
        if obj.status == Task.STATUS_COMPLETED or not obj.due_date:
            return False
        return obj.due_date < timezone.now().date()

    def validate_title(self, value):
        val = value.strip()
        if not val:
            raise serializers.ValidationError("Task title cannot be empty.")
        return val

    def create(self, validated_data):
        # Database security: Enforce ownership strictly from authenticated request user
        validated_data['creator'] = self.context['request'].user
        return super().create(validated_data)
