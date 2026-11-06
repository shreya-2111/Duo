from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Notification

User = get_user_model()

class NotificationAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(email='nuser@duo.app', name='Notify User', password='password123')
        self.client.force_authenticate(user=self.user)

    def test_list_and_mark_notifications_read(self):
        n1 = Notification.objects.create(
            recipient=self.user,
            title='Budget Alert',
            message='80% spent',
            notification_type='BUDGET_WARNING'
        )
        n2 = Notification.objects.create(
            recipient=self.user,
            title='Task Assigned',
            message='New task',
            notification_type='TASK_ASSIGNED'
        )

        res = self.client.get(reverse('notification_unread_count'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['unread_count'], 2)

        # Mark single as read
        self.client.patch(reverse('notification_mark_read', kwargs={'pk': n1.id}))
        n1.refresh_from_db()
        self.assertTrue(n1.is_read)

        # Mark all as read
        self.client.post(reverse('notification_mark_all_read'))
        n2.refresh_from_db()
        self.assertTrue(n2.is_read)

