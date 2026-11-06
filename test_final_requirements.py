import urllib.request
import urllib.error
import json
import time
import sys

BASE_URL = "http://127.0.0.1:8000/api"

class ApiClient:
    def __init__(self, name="Client"):
        self.name = name
        self.access_token = None
        self.refresh_token = None
        self.user_data = None

    def _request(self, method, endpoint, data=None):
        url = f"{BASE_URL}{endpoint}"
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        if self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"

        req_data = json.dumps(data).encode("utf-8") if data is not None else None
        req = urllib.request.Request(url, data=req_data, headers=headers, method=method)

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                resp_bytes = resp.read()
                resp_json = json.loads(resp_bytes.decode("utf-8")) if resp_bytes else {}
                return resp.status, resp_json
        except urllib.error.HTTPError as e:
            err_bytes = e.read()
            try:
                err_json = json.loads(err_bytes.decode("utf-8")) if err_bytes else {}
            except Exception:
                err_json = {"raw": err_bytes.decode("utf-8", errors="replace")}
            return e.code, err_json
        except Exception as e:
            return 0, {"error": str(e)}

    def get(self, endpoint):
        return self._request("GET", endpoint)

    def post(self, endpoint, data=None):
        return self._request("POST", endpoint, data)

    def patch(self, endpoint, data=None):
        return self._request("PATCH", endpoint, data)

    def delete(self, endpoint):
        return self._request("DELETE", endpoint)

def run_tests():
    ts = int(time.time())
    results = {}

    print("=" * 70)
    print("   DUO FINAL REQUIREMENTS VERIFICATION TEST SUITE   ")
    print("=" * 70)

    user_a = ApiClient("User A")
    user_b = ApiClient("User B")

    # Test 1: User A Registration & Login
    a_email = f"user_a_{ts}@duo.app"
    a_pw = "PassWord123!"
    code, data = user_a.post("/accounts/register/", {
        "email": a_email,
        "name": "User Alpha",
        "password": a_pw,
    })
    pass1 = (code == 201) and ("tokens" in data)
    if pass1:
        user_a.access_token = data["tokens"]["access"]
        user_a.user_data = data["user"]
    results["1. User A Register & JWT Login"] = pass1
    print(f"[{'PASS' if pass1 else 'FAIL'}] 1. User A Registration & Login (HTTP {code})")

    # Test 2: User B Registration & Login
    b_email = f"user_b_{ts}@duo.app"
    b_pw = "PassWord456!"
    code, data = user_b.post("/accounts/register/", {
        "email": b_email,
        "name": "User Beta",
        "password": b_pw,
    })
    pass2 = (code == 201) and ("tokens" in data)
    if pass2:
        user_b.access_token = data["tokens"]["access"]
        user_b.user_data = data["user"]
    results["2. User B Register & JWT Login"] = pass2
    print(f"[{'PASS' if pass2 else 'FAIL'}] 2. User B Registration & Login (HTTP {code})")

    # Test 3: User A Private Expense Isolation
    code, exp_data = user_a.post("/expenses/", {
        "title": "Alpha Confidential Expense",
        "amount": "1500.00",
        "category": "Shopping",
        "payment_method": "Credit Card",
        "expense_date": "2026-11-05",
        "location": "Bandra Kurla Complex",
        "description": "Private transaction details"
    })
    exp_id = exp_data.get("id") or (exp_data.get("expense", {}).get("id") if isinstance(exp_data.get("expense"), dict) else None)
    pass3_create = (code == 201) and (exp_id is not None)

    code_b_list, b_expenses = user_b.get("/expenses/")
    b_has_a_expense = any(e.get("id") == exp_id for e in b_expenses) if isinstance(b_expenses, list) else False

    code_b_direct, _ = user_b.get(f"/expenses/{exp_id}/")
    code_b_patch, _ = user_b.patch(f"/expenses/{exp_id}/", {"title": "Hacked"})
    code_b_del, _ = user_b.delete(f"/expenses/{exp_id}/")

    pass3 = pass3_create and (not b_has_a_expense) and (code_b_direct == 404) and (code_b_patch == 404) and (code_b_del == 404)
    results["3. Private Expense Strict Isolation"] = pass3
    print(f"[{'PASS' if pass3 else 'FAIL'}] 3. User A Expense Isolation (User B direct GET: {code_b_direct}, PATCH: {code_b_patch}, DELETE: {code_b_del})")

    # Test 4: Monthly Budget Set & Update per User
    code_a_bgt, data_a_bgt = user_a.post("/budgets/current/", {
        "month": 11,
        "year": 2026,
        "amount_limit": "20000.00"
    })
    code_b_bgt, data_b_bgt = user_b.post("/budgets/current/", {
        "month": 11,
        "year": 2026,
        "amount_limit": "50000.00"
    })
    pass4 = (code_a_bgt == 200 or code_a_bgt == 201) and (code_b_bgt == 200 or code_b_bgt == 201)
    results["4. Independent Monthly Budgets"] = pass4
    print(f"[{'PASS' if pass4 else 'FAIL'}] 4. Independent Monthly Budgets (User A: 20000, User B: 50000)")

    # Test 5: Budget Alert Warnings (80%, 100%, >100%) & Non-blocking Overrun
    # User A limit is 20,000. Spent so far: 1,500.
    # Add 15,000 -> total 16,500 (82.5% -> WARNING_80)
    code_w80, data_w80 = user_a.post("/expenses/", {
        "title": "Electronics",
        "amount": "15000.00",
        "category": "Shopping",
        "expense_date": "2026-11-05"
    })
    st_80 = data_w80.get("budget_status", {}).get("alert_level")

    # Add 3,500 -> total 20,000 (100% -> REACHED_100)
    code_w100, data_w100 = user_a.post("/expenses/", {
        "title": "Groceries",
        "amount": "3500.00",
        "category": "Food",
        "expense_date": "2026-11-05"
    })
    st_100 = data_w100.get("budget_status", {}).get("alert_level")

    # Add 5,000 -> total 25,000 (125% -> OVER_BUDGET)
    code_over, data_over = user_a.post("/expenses/", {
        "title": "Dinner with friends",
        "amount": "5000.00",
        "category": "Food",
        "expense_date": "2026-11-05"
    })
    st_over = data_over.get("budget_status", {}).get("alert_level")
    pass5 = (st_80 == "WARNING_80") and (st_100 == "REACHED_100") and (st_over == "OVER_BUDGET") and (code_over == 201)
    results["5. Budget Alert Thresholds (80%, 100%, >100%)"] = pass5
    print(f"[{'PASS' if pass5 else 'FAIL'}] 5. Budget Alerts: 80% ({st_80}), 100% ({st_100}), >100% ({st_over}) - Logging unblocked: HTTP {code_over}")

    # Test 6: Personal Task Creation with Reminders, Priority, Repeat & Isolation
    code_task, task_data = user_a.post("/tasks/", {
        "title": "Pay Monthly Rent",
        "description": "Transfer to landlord bank account",
        "category": "Bills",
        "priority": "HIGH",
        "due_date": "2026-11-10",
        "due_time": "18:00:00",
        "repeat_type": "MONTHLY",
        "has_reminder": True,
        "reminder_time": "12:00:00"
    })
    task_id = task_data.get("id")
    pass6_create = (code_task == 201) and (task_id is not None) and (task_data.get("repeat_type") == "MONTHLY")

    # User B cannot see or manipulate User A's task
    code_b_tasks, b_tasks = user_b.get("/tasks/")
    b_has_a_task = any(t.get("id") == task_id for t in b_tasks) if isinstance(b_tasks, list) else False
    code_b_get_task, _ = user_b.get(f"/tasks/{task_id}/")
    code_b_toggle, _ = user_b.patch(f"/tasks/{task_id}/toggle/")
    code_b_del_task, _ = user_b.delete(f"/tasks/{task_id}/")

    pass6 = pass6_create and (not b_has_a_task) and (code_b_get_task == 404) and (code_b_toggle == 404) and (code_b_del_task == 404)
    results["6. Personal Task CRUD & Strict Isolation"] = pass6
    print(f"[{'PASS' if pass6 else 'FAIL'}] 6. Personal Task Created & Isolated (User B GET: {code_b_get_task}, TOGGLE: {code_b_toggle})")

    # Test 7: Task Status Toggle & Date Filter
    code_toggle, toggle_data = user_a.patch(f"/tasks/{task_id}/toggle/")
    is_done = toggle_data.get("is_done")
    code_filter, filtered_tasks = user_a.get(f"/tasks/?due_date=2026-11-10")
    pass7 = (code_toggle == 200) and (is_done is True) and (len(filtered_tasks) >= 1)
    results["7. Task Toggle & Date Filtering"] = pass7
    print(f"[{'PASS' if pass7 else 'FAIL'}] 7. Task Status Toggle & Date Filtering (is_done: {is_done})")

    # Test 8: Dashboard Overview (Personal Budget, Spending Analytics, Tasks)
    code_dash, dash_data = user_a.get("/accounts/dashboard/")
    pass8 = (
        code_dash == 200
        and "budget_summary" in dash_data
        and "spending_analytics" in dash_data
        and "recent_expenses" in dash_data
        and "today_tasks" in dash_data
        and "task_stats" in dash_data
        and dash_data.get("shared_tasks") == []
    )
    results["8. Unified Personal Dashboard API"] = pass8
    print(f"[{'PASS' if pass8 else 'FAIL'}] 8. Personal Dashboard API (Spending Analytics: {len(dash_data.get('spending_analytics', []))} categories)")

    # Test 9: Forgot Password & Password Reset Flow
    code_forgot, forgot_data = user_a.post("/accounts/forgot-password/", {
        "email": a_email
    })
    reset_token = forgot_data.get("reset_token")

    new_pw = "BrandNewSecret789!"
    code_reset, reset_data = user_a.post("/accounts/reset-password/", {
        "email": a_email,
        "token": reset_token,
        "new_password": new_pw
    })

    login_client = ApiClient("Login Test")
    code_login_new, login_data = login_client.post("/accounts/login/", {
        "email": a_email,
        "password": new_pw
    })
    pass9 = (code_forgot == 200) and (reset_token is not None) and (code_reset == 200) and (code_login_new == 200)
    results["9. Forgot & Reset Password Flow"] = pass9
    print(f"[{'PASS' if pass9 else 'FAIL'}] 9. Password Reset Flow (Forgot: {code_forgot}, Reset: {code_reset}, Login with new password: {code_login_new})")

    # Test 10: Collaboration Endpoints Deprecation
    code_dep1, _ = user_a.get("/connections/current/")
    code_dep2, _ = user_a.post("/connections/generate-code/", {})
    code_dep3, _ = user_a.post("/connections/redeem-invite/", {})
    pass10 = (code_dep1 == 410) and (code_dep2 == 410) and (code_dep3 == 410)
    results["10. Collaboration Endpoints Deprecated (410 GONE)"] = pass10
    print(f"[{'PASS' if pass10 else 'FAIL'}] 10. Collaboration Endpoints Deprecated (Returned 410 GONE)")

    # Test 11: Unauthorized Access Rejection
    anon = ApiClient("Anonymous")
    c_anon_exp, _ = anon.get("/expenses/")
    c_anon_tsk, _ = anon.get("/tasks/")
    c_anon_bgt, _ = anon.get("/budgets/current/")
    c_anon_dsh, _ = anon.get("/accounts/dashboard/")
    pass11 = (c_anon_exp == 401) and (c_anon_tsk == 401) and (c_anon_bgt == 401) and (c_anon_dsh == 401)
    results["11. Unauthenticated Requests Rejected (401)"] = pass11
    print(f"[{'PASS' if pass11 else 'FAIL'}] 11. Security: Anonymous Requests Rejected (HTTP 401 on all endpoints)")

    print("=" * 70)
    passed_cnt = sum(1 for v in results.values() if v)
    total_cnt = len(results)
    print(f"SUMMARY: {passed_cnt}/{total_cnt} TESTS PASSED ({passed_cnt/total_cnt*100:.1f}%)")
    print("=" * 70)
    return passed_cnt == total_cnt

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
