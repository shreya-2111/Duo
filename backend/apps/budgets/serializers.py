from rest_framework import serializers
from .models import Budget

class BudgetSerializer(serializers.ModelSerializer):
    summary = serializers.SerializerMethodField()

    class Meta:
        model = Budget
        fields = ['id', 'month', 'year', 'amount_limit', 'created_at', 'summary']
        read_only_fields = ['id', 'created_at', 'summary']

    def get_summary(self, obj):
        return obj.get_summary()

    def validate_month(self, value):
        if value < 1 or value > 12:
            raise serializers.ValidationError("Month must be between 1 and 12.")
        return value

    def validate_amount_limit(self, value):
        if value <= 0:
            raise serializers.ValidationError("Budget limit must be greater than zero.")
        return value

    def create(self, validated_data):
        user = self.context['request'].user
        budget, _ = Budget.objects.update_or_create(
            user=user,
            month=validated_data['month'],
            year=validated_data['year'],
            defaults={'amount_limit': validated_data['amount_limit']}
        )
        return budget
