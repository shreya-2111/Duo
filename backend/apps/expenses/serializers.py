from rest_framework import serializers
from .models import Expense

class ExpenseSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source='owner.name', read_only=True)

    class Meta:
        model = Expense
        fields = [
            'id', 'title', 'amount', 'category', 'description',
            'location', 'payment_method', 'expense_date', 'receipt',
            'owner_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'owner_name', 'created_at', 'updated_at']

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Expense amount must be greater than zero.")
        return value

    def create(self, validated_data):
        # Requirement 5: Never trust user_id supplied by client
        validated_data['owner'] = self.context['request'].user
        return super().create(validated_data)
