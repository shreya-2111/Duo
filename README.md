# Duo

> **Money Managed. Tasks Shared.**

Duo is a full-stack mobile application built for couples, roommates, and accountability partners. It provides strict personal privacy for personal finances and monthly budgets, while seamlessly synchronizing shared to-dos and task assignments.

---

## Brand & Design Direction
* **Primary Color**: `#8B5CF6` (Premium Lavender Purple)
* **Background Color**: `#F8F7FC` (Clean Light Surface)
* **Accents**: Soft Lavender `#EDE5FF` / `#DCCEFF`, Mint `#D9F2E5`, Peach `#FFE2D6`
* **Theme**: Premium light lavender & white (Strictly light mode)
* **Currency**: Indian Rupee (`₹` INR)
* **Timezone**: `Asia/Kolkata`

---

## Monorepo Project Structure

```
Duo/
├── DUO_Logos/            # Official brand assets (PNG, SVG, JPG, PDF)
│
├── backend/              # Python Django + Django REST Framework + MySQL
│   ├── venv/             # Python 3.14 virtual environment
│   ├── duo_backend/      # Project settings, JWT auth, MySQL config, URLs
│   ├── apps/
│   │   ├── accounts/         # Custom User model, JWT token views, profile, dashboard
│   │   ├── connections/      # Unique invitation codes & partner linking
│   │   ├── expenses/         # Private expenses (INR), monthly summary
│   │   ├── budgets/          # Monthly budgets & 80%, 100%, >100% alert engine
│   │   ├── tasks/            # Personal (private) vs Shared tasks (assignable)
│   │   └── notifications/    # Partner task & connection notifications
│   ├── manage.py
│   ├── requirements.txt
│   └── .env.example
│
├── mobile/               # Flutter 3.41.2 + SQLite local cache
│   ├── assets/
│   │   ├── icons/        # Brand icons and logos
│   │   └── images/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/         # Theme, ApiService, AuthStorage, SQLite LocalDb, Formatters
│   │   ├── features/     # Auth, Dashboard, Expenses, Budgets, Tasks, Partner, Profile
│   │   └── shared/       # DuoButton, BudgetAlertBadge, DuoCards
│   ├── test/             # Unit and widget test suite (12/12 passing)
│   └── build/            # Output directory for release APK
│
└── test_qa_audit.py      # Automated 16-case QA Audit Suite for 2-user testing
```

---

## Test Accounts (Pre-Seeded)

Run `python manage.py seed_demo_data` in the backend folder to initialize demo accounts:

| User | Email | Password | Role / Budget |
| :--- | :--- | :--- | :--- |
| **User A (You)** | `alex.sharma@duo.app` | `password123` | Alex Sharma (₹35,000/mo budget) |
| **User B (Partner)** | `priya.patel@duo.app` | `password123` | Priya Patel (₹40,000/mo budget) |
| **Admin** | `admin@duo.com` | `admin1234` | System Administrator |

---

## Quality Assurance & Verification

### 1. Two-User End-to-End QA Audit (16 Cases)
Run the automated two-user test suite against the live backend:
```powershell
python test_qa_audit.py
```
*Result: 16 / 16 PASSED.*

### 2. Backend Tests & Checks
```powershell
cd backend
.\venv\Scripts\activate
python manage.py check
python manage.py test apps.accounts apps.connections apps.budgets apps.expenses apps.tasks apps.notifications
```
*Result: 28 / 28 PASSED.*

### 3. Flutter Tests & Static Analysis
```powershell
cd mobile
flutter analyze
flutter test
```
*Result: 0 analysis issues, 12 / 12 tests passed.*

---

## How to Run

### 1. Start the Backend (Django + MySQL)
```powershell
cd backend
.\venv\Scripts\activate
python manage.py migrate
python manage.py seed_demo_data
python manage.py runserver 0.0.0.0:8000
```

### 2. Run the Mobile App (Flutter)

#### A. Web Browser (Chrome)
To run in Chrome without font network latency:
```powershell
cd mobile
flutter run -d chrome --web-renderer html
```

#### B. Android Device or Emulator
Connect your Android phone via USB (with USB Debugging enabled) or start an Android Emulator:
```powershell
cd mobile
flutter run
```

---

## Free Cloud Deployment (Zero Paid Subscriptions)

To use Duo across different cities (e.g., Ahmedabad and Delhi) without keeping your laptop on:

### Step 1: 100% Free MySQL Database (TiDB Cloud Serverless)
1. Sign up for free at [tidbcloud.com](https://tidbcloud.com) (No credit card required, 5GB free forever).
2. Create a **Serverless** cluster (name: `duo_db`).
3. Set Security > IP Access List to `0.0.0.0/0` (Allow from anywhere).
4. Copy the connection string (`mysql://<user>:<password>@<host>:4000/<db>?ssl_mode=VERIFY_IDENTITY`).
5. Test your connection locally:
   ```powershell
   $env:DATABASE_URL="your-tidb-connection-string"
   python backend/test_tidb_connection.py
   ```

### Step 2: 100% Free Backend Web Service (Render)
1. Push this project to your GitHub account (Free repository).
2. Go to [render.com](https://render.com) and create a **Free Web Service** connected to your GitHub repository.
3. Configure settings:
   * **Root Directory:** `backend`
   * **Runtime:** `Python 3`
   * **Build Command:** `chmod +x build.sh && ./build.sh`
   * **Start Command:** `gunicorn duo_backend.wsgi:application --bind 0.0.0.0:$PORT --workers 3 --timeout 120`
   * **Health Check Path:** `/api/health/`
4. In the **Environment** tab, add:
   * `DEBUG` = `False`
   * `ALLOWED_HOSTS` = `.onrender.com,localhost,127.0.0.1`
   * `CORS_ALLOW_ALL_ORIGINS` = `True`
   * `DATABASE_URL` = `<your-tidb-connection-string>`
5. Deploy service. Once deployed, verify `https://<your-service>.onrender.com/api/health/` returns `{"status": "healthy", "database": "connected"}`.

---

## Building the Release Android APK for Delhi / Cross-City Use

Once your backend is live on Render:
```powershell
cd mobile
flutter build apk --release --dart-define=API_URL=https://<your-service>.onrender.com/api
```
* **Release APK:** `mobile/build/app/outputs/flutter-apk/app-release.apk`
* You can send this APK to your friend in Delhi via WhatsApp, Google Drive, or Telegram. Both accounts will connect seamlessly over HTTPS to the cloud database with full data persistence and private account isolation.
