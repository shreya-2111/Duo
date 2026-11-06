from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

class AccountsAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='testuser@duo.app',
            name='Test User',
            password='password123'
        )

    def test_user_registration(self):
        res = self.client.post(reverse('account_register'), {
            'email': 'newuser@duo.app',
            'name': 'New User',
            'password': 'password123'
        })
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('tokens', res.data)
        self.assertIn('access', res.data['tokens'])

    def test_user_login(self):
        res = self.client.post(reverse('account_login'), {
            'email': 'testuser@duo.app',
            'password': 'password123'
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('tokens', res.data)
        self.assertEqual(res.data['user']['email'], 'testuser@duo.app')

    def test_user_profile_authenticated(self):
        self.client.force_authenticate(user=self.user)
        res = self.client.get(reverse('account_profile'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['email'], 'testuser@duo.app')

    def test_dashboard_overview(self):
        self.client.force_authenticate(user=self.user)
        res = self.client.get(reverse('account_dashboard'))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('budget_summary', res.data)
        self.assertIn('recent_expenses', res.data)
        self.assertIn('spending_analytics', res.data)
        self.assertIn('task_stats', res.data)

    def test_forgot_and_reset_password_flow(self):
        # 1. Request forgot password
        forgot_res = self.client.post(reverse('account_forgot_password'), {
            'email': 'testuser@duo.app'
        })
        self.assertEqual(forgot_res.status_code, status.HTTP_200_OK)
        token = forgot_res.data.get('reset_token')
        self.assertIsNotNone(token)

        # 2. Reset password using token
        reset_res = self.client.post(reverse('account_reset_password'), {
            'email': 'testuser@duo.app',
            'token': token,
            'new_password': 'newpassword456',
        })
        self.assertEqual(reset_res.status_code, status.HTTP_200_OK)

        # 3. Verify login works with new password
        login_res = self.client.post(reverse('account_login'), {
            'email': 'testuser@duo.app',
            'password': 'newpassword456',
        })
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)
