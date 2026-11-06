from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Task

User = get_user_model()

class PersonalTaskAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user1 = User.objects.create_user(email='user1@duo.app', name='User 1', password='password123')
        self.user2 = User.objects.create_user(email='user2@duo.app', name='User 2', password='password123')

    def test_create_and_read_personal_task(self):
        self.client.force_authenticate(user=self.user1)
        res = self.client.post(reverse('task_list_create'), {
            'title': 'Pay electricity bill',
            'description': 'Before the 15th',
            'priority': 'HIGH',
            'category': 'Finance',
            'due_date': '2026-11-15',
            'due_time': '18:30:00',
            'repeat_type': 'MONTHLY',
            'has_reminder': True,
            'reminder_time': '17:00:00',
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['title'], 'Pay electricity bill')
        self.assertEqual(res.data['priority'], 'HIGH')
        self.assertEqual(res.data['category'], 'Finance')
        self.assertTrue(res.data['has_reminder'])
        self.assertEqual(res.data['repeat_type'], 'MONTHLY')

        # Read back user1's task list
        list_res = self.client.get(reverse('task_list_create'))
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_res.data), 1)

    def test_strict_isolation_user2_cannot_access_user1_tasks(self):
        # User 1 creates a private task
        self.client.force_authenticate(user=self.user1)
        res = self.client.post(reverse('task_list_create'), {
            'title': 'User 1 Confidential Task',
            'priority': 'MEDIUM',
        })
        task_id = res.data['id']

        # User 2 lists tasks - must see 0 tasks
        self.client.force_authenticate(user=self.user2)
        u2_list = self.client.get(reverse('task_list_create'))
        self.assertEqual(len(u2_list.data), 0)

        # User 2 cannot retrieve User 1's task directly
        u2_detail = self.client.get(reverse('task_detail', kwargs={'pk': task_id}))
        self.assertEqual(u2_detail.status_code, status.HTTP_404_NOT_FOUND)

        # User 2 cannot update User 1's task
        u2_update = self.client.patch(reverse('task_detail', kwargs={'pk': task_id}), {'title': 'Hacked'})
        self.assertEqual(u2_update.status_code, status.HTTP_404_NOT_FOUND)

        # User 2 cannot toggle User 1's task
        u2_toggle = self.client.patch(reverse('task_toggle', kwargs={'pk': task_id}))
        self.assertEqual(u2_toggle.status_code, status.HTTP_404_NOT_FOUND)

        # User 2 cannot delete User 1's task
        u2_delete = self.client.delete(reverse('task_detail', kwargs={'pk': task_id}))
        self.assertEqual(u2_delete.status_code, status.HTTP_404_NOT_FOUND)

    def test_toggle_and_edit_task(self):
        self.client.force_authenticate(user=self.user1)
        res = self.client.post(reverse('task_list_create'), {
            'title': 'Workout routine',
            'priority': 'LOW',
        })
        task_id = res.data['id']

        # Toggle to completed
        toggle_res = self.client.patch(reverse('task_toggle', kwargs={'pk': task_id}))
        self.assertEqual(toggle_res.status_code, status.HTTP_200_OK)
        self.assertTrue(toggle_res.data['is_done'])
        self.assertEqual(toggle_res.data['status'], Task.STATUS_COMPLETED)

        # Toggle back to pending
        toggle_res2 = self.client.patch(reverse('task_toggle', kwargs={'pk': task_id}))
        self.assertEqual(toggle_res2.status_code, status.HTTP_200_OK)
        self.assertFalse(toggle_res2.data['is_done'])
        self.assertEqual(toggle_res2.data['status'], Task.STATUS_PENDING)

        # Update title and priority
        update_res = self.client.patch(reverse('task_detail', kwargs={'pk': task_id}), {
            'title': 'Morning Run 5K',
            'priority': 'HIGH',
        })
        self.assertEqual(update_res.status_code, status.HTTP_200_OK)
        self.assertEqual(update_res.data['title'], 'Morning Run 5K')
        self.assertEqual(update_res.data['priority'], 'HIGH')

        # Delete task
        del_res = self.client.delete(reverse('task_detail', kwargs={'pk': task_id}))
        self.assertEqual(del_res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Task.objects.filter(id=task_id).count(), 0)

    def test_filter_by_date_and_category(self):
        self.client.force_authenticate(user=self.user1)
        Task.objects.create(creator=self.user1, title='T1', category='Work', due_date='2026-11-10', priority='HIGH')
        Task.objects.create(creator=self.user1, title='T2', category='Personal', due_date='2026-11-20', priority='LOW')

        # Filter category Work
        r_work = self.client.get(reverse('task_list_create') + '?category=Work')
        self.assertEqual(len(r_work.data), 1)
        self.assertEqual(r_work.data[0]['title'], 'T1')

        # Filter date range
        r_date = self.client.get(reverse('task_list_create') + '?start_date=2026-11-01&end_date=2026-11-15')
        self.assertEqual(len(r_date.data), 1)
        self.assertEqual(r_date.data[0]['title'], 'T1')
