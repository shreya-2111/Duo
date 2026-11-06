# Duo Backend API

> **Tagline**: Money Managed. Tasks Shared.  
> **Framework**: Python 3.14 + Django 5.2 + Django REST Framework + SimpleJWT  
> **Database**: MySQL 8.0 (`duo_db`) with PyMySQL  
> **Timezone**: `Asia/Kolkata`  
> **Currency**: Indian Rupee (`₹` INR)

---

## Modular Apps Architecture

The backend is organized into 6 modular apps adhering to separation of concerns:

1. **`apps.accounts`**: Custom User model (`accounts.User`), JWT registration, login, logout with token blacklisting, user profile, and unified dashboard API.
2. **`apps.connections`**: Shared spaces, space memberships (OWNER / MEMBER), and one-time cryptographically hashed invitation codes (SHA-256).
3. **`apps.budgets`**: Individual monthly budgets (one per user per month/year), non-blocking alert calculations at 80%, 100%, and >100%.
4. **`apps.expenses`**: 100% private expense tracking with owner, category, title, amount (`DecimalField`), description, location, payment method, date, and receipt upload.
5. **`apps.tasks`**: Personal tasks (strictly private to creator) and Shared tasks (strictly scoped to shared-space members with assignee validation).
6. **`apps.notifications`**: In-app notifications for budget alerts, task assignments, task completions, and space invites.

---

## Security & Permission Highlights

* **Ownership Enforced**: Client-supplied `user_id` or `owner_id` is never trusted. Ownership is injected from `request.user` on every write operation.
* **Strict Privacy Isolation**: Expenses and monthly budgets are strictly query-filtered by `owner=request.user`. Even connected partners cannot access or view another user's financial data.
* **Secure Invitation Codes**: Codes (e.g. `DUO-XXXXXX`) are never stored in plain text. Only a SHA-256 cryptographic hash is stored in MySQL. Codes expire (default 48h) and are strictly single-use.
* **Space Membership Verification**: Users can only create or view shared tasks within spaces where they hold active membership. Task assignees must also belong to the target space.

---

## Setup & Running Instructions

### 1. Prerequisites
* Python 3.12+ / 3.14
* MySQL Server 8.0 running on `127.0.0.1:3306`

### 2. Configure Environment (`.env`)
Create a `.env` file in `backend/` based on `.env.example`:
```env
SECRET_KEY=your-production-secret-key-here
DEBUG=True
ALLOWED_HOSTS=127.0.0.1,localhost,0.0.0.0

DB_ENGINE=mysql
DB_NAME=duo_db
DB_USER=root
DB_PASSWORD="your_mysql_password"
DB_HOST=127.0.0.1
DB_PORT=3306

CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### 3. Initialize & Migrate
```powershell
# Activate Python Virtual Environment
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Apply Migrations to MySQL
python manage.py migrate

# Create Admin Superuser (if not already created)
python manage.py createsuperuser
```

### 4. Run Development Server
```powershell
python manage.py runserver 0.0.0.0:8000
```

### 5. Run Automated Tests
```powershell
python manage.py test apps.accounts apps.connections apps.budgets apps.expenses apps.tasks apps.notifications
```

---

## API Endpoints Reference

### 1. Accounts & Authentication (`/api/accounts/`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/accounts/register/` | Public | Register new account and receive JWT access & refresh tokens |
| `POST` | `/api/accounts/login/` | Public | Authenticate via email & password, receive tokens |
| `POST` | `/api/accounts/token/refresh/` | Public | Exchange refresh token for new access token |
| `POST` | `/api/accounts/logout/` | Bearer | Blacklist refresh token and logout |
| `GET` | `/api/accounts/profile/` | Bearer | Get authenticated user profile |
| `PATCH` | `/api/accounts/profile/` | Bearer | Update user profile (name, avatar) |
| `GET` | `/api/accounts/dashboard/` | Bearer | Unified dashboard payload (budget, recent expenses, tasks, notifications) |

### 2. Shared Spaces & Connections (`/api/connections/`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/connections/spaces/` | Bearer | List shared spaces user is member of |
| `POST` | `/api/connections/spaces/` | Bearer | Create a new shared space (creator becomes OWNER) |
| `GET` | `/api/connections/spaces/<id>/` | Bearer | Retrieve space details and member list |
| `POST` | `/api/connections/spaces/<id>/invite/` | Bearer | Generate a single-use SHA-256 hashed invite code |
| `POST` | `/api/connections/spaces/<id>/leave/` | Bearer | Leave space (or delete if last member) |
| `POST` | `/api/connections/redeem-invite/` | Bearer | Redeem raw code to join shared space |

### 3. Monthly Budgets (`/api/budgets/`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/budgets/` | Bearer | List all private monthly budgets of authenticated user |
| `POST` | `/api/budgets/` | Bearer | Create or update budget for month & year |
| `GET` | `/api/budgets/current/` | Bearer | Current month budget + spending summary + 80%/100% alert status |
| `POST` | `/api/budgets/current/` | Bearer | Set or update current month's budget limit |
| `GET` | `/api/budgets/<id>/` | Bearer | Retrieve specific budget record (strictly owner) |
| `PUT/PATCH` | `/api/budgets/<id>/` | Bearer | Update budget record |
| `DELETE` | `/api/budgets/<id>/` | Bearer | Delete budget record |

### 4. Private Expenses (`/api/expenses/`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/expenses/` | Bearer | List private expenses (`?month=`, `?year=`, `?category=`, `?search=`) |
| `POST` | `/api/expenses/` | Bearer | Create expense (7 fields + receipt). Triggers non-blocking budget alert |
| `GET` | `/api/expenses/<id>/` | Bearer | Retrieve expense (strictly owner) |
| `PUT/PATCH` | `/api/expenses/<id>/` | Bearer | Update expense |
| `DELETE` | `/api/expenses/<id>/` | Bearer | Delete expense |
| `GET` | `/api/expenses/summary/` | Bearer | Monthly expense breakdown by category, payment method, and daily average |

### 5. Tasks (`/api/tasks/`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/tasks/` | Bearer | List tasks (`?visibility=PERSONAL\|SHARED`, `?status=`, `?priority=`) |
| `POST` | `/api/tasks/` | Bearer | Create personal or shared task (validates space membership & assignee) |
| `GET` | `/api/tasks/<id>/` | Bearer | Retrieve task details |
| `PUT/PATCH` | `/api/tasks/<id>/` | Bearer | Update task details |
| `PATCH` | `/api/tasks/<id>/toggle/` | Bearer | Toggle status between PENDING & COMPLETED |
| `DELETE` | `/api/tasks/<id>/` | Bearer | Delete task (creator or space owner) |

### 6. Notifications (`/api/notifications/`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/notifications/` | Bearer | List notifications (`?unread=true`) |
| `GET` | `/api/notifications/unread-count/` | Bearer | Get count of unread notifications |
| `PATCH` | `/api/notifications/<id>/read/` | Bearer | Mark specific notification as read |
| `POST` | `/api/notifications/mark-all-read/` | Bearer | Mark all notifications for user as read |

