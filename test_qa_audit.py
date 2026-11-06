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

def run_qa_audit():
    ts = int(time.time())
    results = {}

    print("=" * 72)
    print("   DUO COMPREHENSIVE QUALITY ASSURANCE AUDIT (16 FINAL TEST CASES)   ")
    print("=" * 72)

    user_a = ApiClient("User A")
    user_b = ApiClient("User B")

    # 1. User A Register & Login
    a_email = f"alpha_{ts}@duo.app"
    code1, d1 = user_a.post("/accounts/register/", {
        "email": a_email, "name": "Alpha User", "password": "Password123!"
    })
    p1 = (code1 == 201) and ("tokens" in d1)
    if p1:
        user_a.access_token = d1["tokens"]["access"]
        user_a.user_data = d1["user"]
    results["1. User A registration & login"] = p1
    print(f"[{'PASS' if p1 else 'FAIL'}] 1. User A can register and log in (HTTP {code1})")

    # 2. User B Register & Login
    b_email = f"beta_{ts}@duo.app"
    code2, d2 = user_b.post("/accounts/register/", {
        "email": b_email, "name": "Beta User", "password": "Password123!"
    })
    p2 = (code2 == 201) and ("tokens" in d2)
    if p2:
        user_b.access_token = d2["tokens"]["access"]
        user_b.user_data = d2["user"]
    results["2. User B registration & login"] = p2
    print(f"[{'PASS' if p2 else 'FAIL'}] 2. User B can register and log in (HTTP {code2})")

    # 3. User A Private Expense - User B cannot access
    code3_c, d3_c = user_a.post("/expenses/", {
        "title": "Alpha Private Medical Expense",
        "amount": "2500.00",
        "category": "Health",
        "payment_method": "UPI",
        "expense_date": "2026-11-05"
    })
    exp_id = d3_c.get("id") or (d3_c.get("expense", {}).get("id") if isinstance(d3_c.get("expense"), dict) else None)
    c3_get, _ = user_b.get(f"/expenses/{exp_id}/")
    c3_patch, _ = user_b.patch(f"/expenses/{exp_id}/", {"title": "Breach"})
    c3_del, _ = user_b.delete(f"/expenses/{exp_id}/")
    p3 = (code3_c == 201) and (c3_get == 404) and (c3_patch == 404) and (c3_del == 404)
    results["3. User A private expense inaccessible by User B"] = p3
    print(f"[{'PASS' if p3 else 'FAIL'}] 3. User A private expense isolated (B GET: {c3_get}, PATCH: {c3_patch}, DEL: {c3_del})")

    # 4. Each user creates and updates their own monthly budget
    c4_a, _ = user_a.post("/budgets/current/", {"month": 11, "year": 2026, "amount_limit": "25000.00"})
    c4_b, _ = user_b.post("/budgets/current/", {"month": 11, "year": 2026, "amount_limit": "30000.00"})
    p4 = (c4_a in (200, 201)) and (c4_b in (200, 201))
    results["4. Each user manages their own monthly budget"] = p4
    print(f"[{'PASS' if p4 else 'FAIL'}] 4. Individual monthly budgets set independently (A: 25000, B: 30000)")

    # 5. Budget alerts work at 80%, 100%, and >100%
    # Already spent 2500. Add 17500 -> 20000 (80%)
    _, d5_80 = user_a.post("/expenses/", {"title": "Laptop Repair", "amount": "17500.00", "category": "Bills", "expense_date": "2026-11-05"})
    lvl_80 = d5_80.get("budget_status", {}).get("alert_level")
    # Add 5000 -> 25000 (100%)
    _, d5_100 = user_a.post("/expenses/", {"title": "Grocery Staples", "amount": "5000.00", "category": "Food", "expense_date": "2026-11-05"})
    lvl_100 = d5_100.get("budget_status", {}).get("alert_level")
    # Add 3000 -> 28000 (112% -> OVER_BUDGET)
    code_over, d5_over = user_a.post("/expenses/", {"title": "Concert Ticket", "amount": "3000.00", "category": "Entertainment", "expense_date": "2026-11-05"})
    lvl_over = d5_over.get("budget_status", {}).get("alert_level")
    p5 = (lvl_80 == "WARNING_80") and (lvl_100 == "REACHED_100") and (lvl_over == "OVER_BUDGET")
    results["5. Budget alerts at 80%, 100%, and >100%"] = p5
    print(f"[{'PASS' if p5 else 'FAIL'}] 5. Budget alert levels: 80% ({lvl_80}), 100% ({lvl_100}), >100% ({lvl_over})")

    # 6. Expenses can still be added after budget overrun
    p6 = (code_over == 201)
    results["6. Non-blocking expense creation on budget overrun"] = p6
    print(f"[{'PASS' if p6 else 'FAIL'}] 6. Expenses successfully logged after exceeding budget (HTTP {code_over})")

    # 7. Collaboration Invitation Generation is Deprecated
    c7, _ = user_a.post("/connections/generate-code/", {})
    p7 = (c7 == 410)
    results["7. Invitation generation deprecated (410 GONE)"] = p7
    print(f"[{'PASS' if p7 else 'FAIL'}] 7. Invitation generation removed/deprecated (HTTP {c7} GONE)")

    # 8. Collaboration Redemption is Deprecated
    c8, _ = user_b.post("/connections/redeem-invite/", {"code": "FAKE123"})
    p8 = (c8 == 410)
    results["8. Invitation redemption deprecated (410 GONE)"] = p8
    print(f"[{'PASS' if p8 else 'FAIL'}] 8. Invitation redemption removed/deprecated (HTTP {c8} GONE)")

    # 9. Collaboration Spaces are Deprecated
    c9, _ = user_a.get("/connections/spaces/")
    p9 = (c9 == 410)
    results["9. Shared spaces deprecated (410 GONE)"] = p9
    print(f"[{'PASS' if p9 else 'FAIL'}] 9. Shared spaces removed/deprecated (HTTP {c9} GONE)")

    # 10. User A creates personal task with reminders, repeat, priority
    c10, d10 = user_a.post("/tasks/", {
        "title": "Quarterly Financial Audit",
        "description": "Collate receipts and investment statements",
        "category": "Finance",
        "priority": "HIGH",
        "due_date": "2026-11-20",
        "due_time": "17:00:00",
        "repeat_type": "MONTHLY",
        "has_reminder": True,
        "reminder_time": "10:00:00"
    })
    task_id = d10.get("id")
    p10 = (c10 == 201) and (d10.get("has_reminder") is True) and (d10.get("repeat_type") == "MONTHLY")
    results["10. Personal task creation with reminders & repeat"] = p10
    print(f"[{'PASS' if p10 else 'FAIL'}] 10. Personal task created with reminders & repeat (HTTP {c10})")

    # 11. User B cannot see or access User A's task
    c11_get, _ = user_b.get(f"/tasks/{task_id}/")
    c11_toggle, _ = user_b.patch(f"/tasks/{task_id}/toggle/")
    c11_del, _ = user_b.delete(f"/tasks/{task_id}/")
    p11 = (c11_get == 404) and (c11_toggle == 404) and (c11_del == 404)
    results["11. User B cannot see or manipulate User A task"] = p11
    print(f"[{'PASS' if p11 else 'FAIL'}] 11. Task isolated from User B (GET: {c11_get}, TOGGLE: {c11_toggle}, DEL: {c11_del})")

    # 12. User A toggles status and updates task
    c12_tog, d12_tog = user_a.patch(f"/tasks/{task_id}/toggle/")
    is_done = d12_tog.get("is_done")
    c12_up, d12_up = user_a.patch(f"/tasks/{task_id}/", {"title": "Updated Financial Audit Title"})
    p12 = (c12_tog == 200) and (is_done is True) and (c12_up == 200) and (d12_up.get("title") == "Updated Financial Audit Title")
    results["12. Task status toggle and update"] = p12
    print(f"[{'PASS' if p12 else 'FAIL'}] 12. Task toggle and update verified (is_done: {is_done})")

    # 13. Personal tasks remain strictly private
    _, b_task_list = user_b.get("/tasks/")
    b_sees_a_task = any(t.get("id") == task_id for t in b_task_list) if isinstance(b_task_list, list) else False
    p13 = (not b_sees_a_task)
    results["13. Strict personal task privacy in querysets"] = p13
    print(f"[{'PASS' if p13 else 'FAIL'}] 13. Personal task list private: User B sees {len(b_task_list) if isinstance(b_task_list, list) else 0} tasks")

    # 14. Unauthorized API requests rejected
    anon = ApiClient("Anon")
    c14_e, _ = anon.get("/expenses/")
    c14_t, _ = anon.get("/tasks/")
    c14_b, _ = anon.get("/budgets/current/")
    c14_d, _ = anon.get("/accounts/dashboard/")
    p14 = (c14_e == 401) and (c14_t == 401) and (c14_b == 401) and (c14_d == 401)
    results["14. Unauthorized requests rejected (HTTP 401)"] = p14
    print(f"[{'PASS' if p14 else 'FAIL'}] 14. Security: Anonymous requests rejected with HTTP 401")

    # 15. Dashboard Overview returns real personal data
    c15, d15 = user_a.get("/accounts/dashboard/")
    p15 = (
        c15 == 200
        and "budget_summary" in d15
        and "spending_analytics" in d15
        and "task_stats" in d15
        and d15.get("shared_tasks") == []
    )
    results["15. Dashboard integration & category spending analytics"] = p15
    print(f"[{'PASS' if p15 else 'FAIL'}] 15. Dashboard overview: budget, {len(d15.get('spending_analytics', []))} spending categories, task stats")

    # 16. Forgot Password & Reset Password Flow
    c16_f, d16_f = user_a.post("/accounts/forgot-password/", {"email": a_email})
    tok = d16_f.get("reset_token")
    c16_r, _ = user_a.post("/accounts/reset-password/", {
        "email": a_email, "token": tok, "new_password": "NewSecretPass789!"
    })
    c16_log, _ = ApiClient("NewLog").post("/accounts/login/", {
        "email": a_email, "password": "NewSecretPass789!"
    })
    p16 = (c16_f == 200) and (tok is not None) and (c16_r == 200) and (c16_log == 200)
    results["16. Password reset token and password update flow"] = p16
    print(f"[{'PASS' if p16 else 'FAIL'}] 16. Password reset flow: token issued, reset confirmed, logged in with new password")

    print("=" * 72)
    passed_cnt = sum(1 for v in results.values() if v)
    total_cnt = len(results)
    print(f"FINAL AUDIT RESULT: {passed_cnt}/{total_cnt} TESTS PASSED ({passed_cnt/total_cnt*100:.1f}%)")
    print("=" * 72)
    return passed_cnt == total_cnt

if __name__ == "__main__":
    success = run_qa_audit()
    sys.exit(0 if success else 1)
