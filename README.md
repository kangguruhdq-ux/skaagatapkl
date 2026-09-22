# SKAGATA PKL Intelligence — Production Full-Stack Mobile Platform

<p align="center">
  <img src="design_specs/assets/SKAGATA_PKL_Intelligence_Brand_Logo.png" width="90" alt="SKAGATA Logo"/>
  <br/>
  <b>SMKN 3 Yogyakarta • Sistem Presensi Geofence, AI Logbook & Telemetri Kompetensi PKL</b>
</p>

---

## 1. Project Overview
**SKAGATA PKL Intelligence** is a production-grade full-stack mobile platform engineered specifically for vocational high school internship (Praktek Kerja Lapangan / PKL) monitoring, geofenced GPS telemetry, AI-driven logbook competency extraction, and industry skill gap analytics at **SMKN 3 Yogyakarta**.

Built directly from the verified Stitch MCP high-fidelity design specifications, the platform replaces static manual paperwork with an institutional-grade, real-time telemetry ecosystem connecting students, school supervisors, and industry partners (DUDI).

---

## 2. Architecture & Technology Stack

```
STITCH DESIGN SYSTEM
        │
        ▼
FLUTTER MOBILE CLIENT (Android / Web / iOS)
  ├── State Management: Provider (Clean Feature-Oriented)
  ├── Networking: ApiClient (Token Refresh Interceptors)
  ├── Storage: FlutterSecureStorage + SharedPreferences
  └── Design System: Plus Jakarta Sans + Inter + Deep Electric Blue (#1D4ED8)
        │
        ▼ REST APIs & WebSocket Telemetry
FASTAPI BACKEND SERVICE (Python 3.9+)
  ├── Security: JWT Access/Refresh, Bcrypt / PBKDF2 Password Hashing, RBAC
  ├── Services: Haversine Geofence Engine, Semantic NLP Skill Extractor, Local Storage
  └── ORM & Database: SQLAlchemy + SQLite (Dev) / PostgreSQL (Prod)
        │
        ▼
PERSISTENT RELATIONAL DATABASE
```

### Mobile App (Flutter / Dart)
- **Framework**: Flutter 3.x with Dart 3.x (Material 3 enabled)
- **State Management**: Clean `ChangeNotifierProvider` architecture with feature separation
- **Networking**: `ApiClient` with automated 401 interceptor, JWT bearer injection, and transparent refresh
- **Local Storage**: `FlutterSecureStorage` for tokens and `SharedPreferences` for hardware IDs and custom endpoints
- **UI Design System**: Faithfully mirrors Stitch specifications (Plus Jakarta Sans headlines, Inter body, `#1D4ED8` electric blue, `#0284C7` analytical cyan, `#10B981` verified emerald, `#F59E0B` amber warning)

### Backend (Python / FastAPI)
- **Framework**: FastAPI (high performance, ASGI, OpenAPI docs at `/api/v1/docs`)
- **Database ORM**: SQLAlchemy 2.0+
- **Migrations**: Alembic
- **Authentication**: JWT token pair (`access_token` expires in 24 hours, `refresh_token` in 30 days)
- **Security**: Strict role-based authorization (`siswa`, `guru`, `mitra`, `admin`), input validation with Pydantic
- **Real-Time Telemetry**: WebSocket endpoint at `/api/v1/ws/telemetry` for live sync status

---

## 3. Implemented Mobile Screens (Stitch Source of Truth)

1. **Login & Multi-Role Authenticator** (`/login`)
   - Official SMKN 3 Yogyakarta emblem with glowing aura and verified badge
   - 4-Role Switcher tabs: `Siswa PKL`, `Guru Pembimbing`, `Mitra Industri`, `Admin PKL`
   - Identifier dynamic helper (NISN / NIP / Partner ID / Admin username)
   - Password input with toggle visibility
   - Hardware telemetry chip bound to device fingerprint
   - FIDO2 biometric authentication trigger
   - Sandbox Quick-Switch demo chips (Fikri, Dra. Wahyuningsih, Ir. Bambang Hermanto)

2. **Student Registration & Dapodik Sync** (`/register`)
   - 3-Step Stepper Ribbon: `1. Data Induk` → `2. Kredensial` → `3. Verif GPS`
   - 3 Role selection cards with icon and descriptive metadata
   - 10-digit NISN field with live `[Dapodik]` auto-fill button
   - Jurusan (Konsentrasi Keahlian) selector (TKJ, TP, TITL, TKR, DKV, TAV)

3. **Student Dashboard & Intelligence Hub** (`/dashboard`)
   - Institutional telemetry ID card with online green status beacon
   - Active placement card: PT Telkom Indonesia Tbk (Witel Yogyakarta)
   - Week 14 / 22 (64%) dual-gradient progress tracker rail
   - Urgent Revision Banner: Ir. Bambang Hermanto's feedback with direct action button
   - Quick Telemetry Strip: 98.4% attendance rate (56 days hadir), 1 day izin, 0 alpa, 38m GPS proximity
   - 4 Field Action Modules: Check-In GPS, Jurnal Harian, Tugas PKL, Unggah Bukti

4. **PKL Placement & Geofence GPS Attendance** (`/attendance`)
   - Registered hardware fingerprint chip (`Samsung Galaxy A54 5G` • `SKGT-DEV-8842`)
   - Radar Geofence Kotabaru visualizer with pulsing concentric radar waves
   - 100m maximum perimeter circle with live student position marker (43m offset)
   - Real-time GPS telemetry HUD (Lat: -7.78542, Long: 110.37219, Accuracy: ±4.2m)
   - Authenticated ticking server clock with shift timing (08:00 - 16:30 WIB)
   - Instant Check-In and Check-Out execution

5. **AI Journal Intelligence & Workflow System** (`/journal`)
   - 5-stage workflow tracker (`Draft` → `Submit` → `AI Sync` → `Review` → `Approved`)
   - SKAGATA AI Engine panel with 98.6% match confidence pill
   - Real-time technical work log editor
   - Telemetry cards for competency standard (`Admin Jaringan Lv. 2`) and complexity tier (`INTERMEDIATE`)
   - AI-extracted technical skill chips (`VLAN 802.1Q`, `L2 Switching`, `STP Protocol`, `Troubleshooting`)
   - Detected hardware/tools tags (`Cisco Catalyst 3850`, `PuTTY Console`, `Fluke Cable Tester`)
   - Full journal creation, editing, and submission modal

6. **Skill Engine & Industry Gap Analytics** (`/skills`)
   - Student Career Focus card with 82.4% readiness index
   - 3 Audit Tiers legend: `AI_DETECTED` (Amber), `SUPERVISOR` (Cyan), `SMKN 3` (Emerald)
   - DUDI Benchmark comparative dual-layer progress bars:
     - Python Scripting: Demand 91%, Student 45% (**GAP -46%**)
     - Computer Networking: Demand 73%, Student 91% (**SURPLUS +18%**)
     - Docker & Container: Demand 64%, Student 31% (**GAP -33%**)
     - MikroTik Routing: Demand 85%, Student 88% (**SURPLUS +3%**)
     - Fiber Optic Splicing: Demand 80%, Student 85% (**SURPLUS +5%**)

7. **Profile & Security Settings** (`/profile`)
   - Student info, class, department, verified status
   - Hardware security binding status
   - Dynamic API base URL switcher (for switching between Emulator `10.0.2.2`, Localhost `127.0.0.1`, and physical LAN IP)
   - Secure logout

---

## 4. Demo Accounts Sandbox Credentials

| Role | Username / Identifier | Password | Name / Description |
|---|---|---|---|
| **Siswa PKL** | `0068492011` | `Skagata123#` | Muhammad Fikri Pratama (XII TKJ 1) |
| **Guru Pembimbing** | `19840217 200801 1 004` | `GuruAktif2025!` | Dra. Sri Wahyuningsih, M.Pd. |
| **Mitra Industri (DUDI)** | `MITRA-TELKOM-092` | `IndustriMitra#1` | Ir. Bambang Hermanto, S.T. (Telkom Witel) |
| **Admin PKL** | `admin_hubin` | `AdminHubin2024!` | Administrator Hubin SMKN 3 Yogyakarta |

---

## 5. Getting Started & Running Locally

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the automated test suite:
   ```bash
   python tests/test_backend.py
   ```
4. Start the FastAPI development server:
   ```bash
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   Open `http://localhost:8000/api/v1/docs` in your browser for the interactive Swagger OpenAPI documentation.

### Mobile App Setup
1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the unit and widget test suite:
   ```bash
   flutter test
   ```
4. Run the mobile application:
   ```bash
   flutter run
   ```
5. Build Release APK:
   ```bash
   flutter build apk --release
   ```
