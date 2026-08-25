# DukaanOS

**The zero-entry ERP for neighborhood shops.**

DukaanOS is a smartphone-first system for kirana stores, bakeries, vegetable shops, hardware stores, and similar small businesses. The shopkeeper should not type stock, bills, and customer credit into an ERP. The phone observes the counter — camera, microphone, and a short review step — and the ledger updates itself.

> The phone observes the shop. AI understands the activity. The ERP updates itself.

This repository is the working product: an **Android Flutter app** (`udyam/`) and a **FastAPI + PostgreSQL backend** (`backend/`). Product and visual direction live in [`udyam/design.md`](udyam/design.md).

---

## What it does today

| Capability | What the shopkeeper experiences |
| --- | --- |
| **Onboarding** | Welcome → shop profile (name, owner, phone, Telegram chat ID, business type) → OTP on Telegram → signed-in shop. |
| **POS** | Live barcode scan, search, custom items, discount, cash or credit checkout. Stock drops; a credit sale writes to khata. |
| **Supplier bills** | Photograph an invoice. Gemini extracts line items. Review, then add stock. Handwriting capture is a fallback when print is unreadable. |
| **Inventory** | Live stock list with quantity, unit, purchase and selling price, supplier, and invoice number. |
| **Khata** | Customer balances, outstanding credit, sales/profit snapshot. Optional always-on voice capture turns spoken Hindi / English / Hinglish into credit and payment entries. |
| **Sessions** | JWT + session ID stored on device. Cold start restores a valid session or returns to welcome. |

The design spec also describes shelf sweeps, stock audits, and a conversational “Ask Dukaan” home. Those are the north star, not all shipped in this codebase yet.

---

## Repository layout

```text
DukaanOS/
├── README.md                 ← you are here
├── backend/                  FastAPI API, Gemini, Telegram OTP, PostgreSQL
│   ├── app/
│   │   ├── main.py           App, lifespan, table create, routers
│   │   ├── config.py         Settings from .env
│   │   ├── dependencies.py   JWT bearer auth
│   │   ├── db/               Async SQLAlchemy engine + session
│   │   ├── models/           users, inventory, sales, khata
│   │   ├── routers/          HTTP endpoints
│   │   ├── schemas/          Pydantic request/response models
│   │   └── services/         Auth, inventory, sales, khata, Gemini, Telegram
│   ├── tests/
│   └── .env.example
└── udyam/                    Flutter client (Android-first)
    ├── lib/
    │   ├── main.dart
    │   ├── constants.dart    API host + route paths
    │   ├── services/         Auth, session, speech, transcript queue
    │   └── screens/          Startup, auth, shell, POS, invoice, inventory, khata
    ├── android/
    ├── test/
    └── design.md             Full UI/UX specification
```

---

## System architecture

```text
 ┌─────────────────────────────────────────────────────────────────┐
 │                     Android phone (Flutter)                     │
 │                                                                 │
 │  Camera          Mic                    Local storage           │
 │  • ML Kit        • ML Kit GenAI STT     • SharedPreferences     │
 │    barcode       • speech_to_text       • SQLite transcript     │
 │  • Invoice         fallback               queue (offline)       │
 │    photo                                                        │
 │  • On-device                                                    │
 │    text / ink                                                   │
 │                                                                 │
 │              HTTP + Bearer JWT  ──────────────┐                 │
 └───────────────────────────────────────────────┼─────────────────┘
                                                 │
                         ┌───────────────────────▼────────────────┐
                         │         FastAPI  (DukaanOS API)        │
                         │  /health  +  /api/*                    │
                         │                                        │
                         │  Auth  Invoices  Inventory  Sales      │
                         │  Khata                                 │
                         └───────┬──────────────┬─────────┬───────┘
                                 │              │         │
                    ┌────────────▼──┐   ┌───────▼──┐  ┌───▼────────┐
                    │  PostgreSQL   │   │  Gemini  │  │  Telegram  │
                    │  (shop data)  │   │  Vision  │  │  Bot OTP   │
                    └───────────────┘   │  + text  │  └────────────┘
                                        └──────────┘

 POS also calls UPC Item DB (https://api.upcitemdb.com) to name unknown barcodes.
```

### Why this split

- **On device:** scanning, listening, and queuing must work at the counter. Camera tabs are created only while selected so the invoice camera is not left running.
- **On the server:** money, stock, and credit need one source of truth, idempotent writes, and a model that can read invoices and shop conversation.
- **Telegram OTP:** shopkeepers already use Telegram; there is no SMS vendor in this stack.

---

## How the pieces work

### 1. Identity and session

1. Shop profile creates a user (`phone` + `telegram_chat_id` unique). The account stays inactive until OTP succeeds.
2. A 6-digit OTP is stored in PostgreSQL and sent with the Telegram Bot API. It expires in **5 minutes**.
3. Verify OTP returns an **access token** (JWT, default **7 days**) and a **session ID** (the user UUID).
4. The app stores both in `SharedPreferences`. Protected APIs send `Authorization: Bearer <token>`.
5. Startup calls `GET /api/auth/session/{session_id}`. Invalid sessions are cleared.

Unverified accounts are cleaned up on a background loop in the API process.

### 2. POS (first tab)

1. Camera + **ML Kit barcode scanning** fills the cart.
2. Known products come from shop inventory. Unknown UPCs are looked up on **UPC Item DB**.
3. Checkout `POST /api/sales/checkout` with a client-generated `checkout_id` (idempotent).
4. The server locks inventory rows, rejects insufficient stock, writes `sales` / `sale_lines`, decrements quantity, and records `inventory_movements` of type `sale`.
5. **Credit** checkout requires a customer name. A khata credit entry is created and linked to the sale. Sale-sourced khata rows cannot be edited or deleted from the khata API.

### 3. Supplier invoice (second tab, labeled Sales)

1. Capture a JPEG of the bill (size and MIME type checked on the server).
2. `POST /api/invoices/analyze` sends the image to **Gemini**. The model must return structured JSON (supplier, line items, totals). Illegible fields stay `null`.
3. The review screen lets the shopkeeper correct lines, then `POST /api/inventory/bulk` upserts by normalized product name + unit and records purchase movements. An optional idempotency key prevents double-add on retry.
4. **Digital ink** handwriting is a fallback path when the printed bill cannot be read.

### 4. Inventory (third tab)

`GET /api/inventory` returns that shop’s items only (`user_id` scoped). Quantities change from invoice bulk-add and from POS checkout, not from typing a spreadsheet.

### 5. Khata and voice (fourth tab)

**Dashboard** (`GET /api/khata/dashboard`) aggregates:

- Sales revenue, cost of goods, units sold
- Purchase spend and remaining stock value
- Customer credit balances
- Recent entries and short insights from analyzed speech

**Voice (optional, consent required):**

1. While the app is in the foreground and **not** on the Khata tab, `ForegroundSpeechService` listens (ML Kit GenAI speech, with `speech_to_text` fallback).
2. Partial transcripts are merged, sealed into batches, and stored in **SQLite** until the network is available.
3. `POST /api/khata/transcripts/analyze` sends each `batch_id` once. Gemini extracts only **explicit** credit / payment / promise language in Hindi, English, or Hinglish.
4. Obligations with confidence ≥ **0.70** become khata entries. Weaker or ambiguous items stay on the dashboard as unresolved. Duplicate `batch_id`s are no-ops.

Listening pauses on the Khata screen so the shopkeeper can read the ledger without the mic competing for attention.

### 6. More (fifth tab)

Placeholder for profile, language, backup, and help. Not a full settings product yet.

---

## Data model (PostgreSQL)

Tables are created on API startup (`Base.metadata.create_all` plus a few idempotent `ALTER TABLE`s for older local databases).

| Table | Role |
| --- | --- |
| `users` | Shop account, Telegram chat ID, shop name/type, `is_active` |
| `otps` | Short-lived login codes |
| `inventory_items` | Per-shop stock; unique on `(user_id, normalized_name, normalized_unit)` |
| `inventory_movements` | Purchase / sale deltas with idempotency keys |
| `sales` / `sale_lines` | Bills; unique `(user_id, checkout_id)` |
| `customers` | Unique on `(user_id, normalized_name)` |
| `khata_entries` | Credit or payment; `source` is `manual`, transcript, or `sale` |
| `transcript_insight_batches` | Gemini output keyed by client `batch_id` |

All shop data is isolated by `user_id`. JWT `sub` is the user UUID.

---

## API surface

Base URL: `http://<host>:8000`  
Interactive docs when the server is running: `/docs`

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/health` | No | Liveness |
| POST | `/api/auth/create-account` | No | Register (inactive until OTP) |
| POST | `/api/auth/create-account/request-otp` | No | Send signup OTP |
| POST | `/api/auth/create-account/verify-otp` | No | Activate + tokens |
| POST | `/api/auth/sign-in/request-otp` | No | Send login OTP |
| POST | `/api/auth/sign-in/verify-otp` | No | Tokens |
| GET | `/api/auth/session/{session_id}` | No | Validate stored session |
| POST | `/api/invoices/analyze` | Bearer | Gemini invoice parse |
| GET | `/api/inventory` | Bearer | List stock |
| POST | `/api/inventory/bulk` | Bearer | Add / merge purchase lines |
| POST | `/api/sales/checkout` | Bearer | Complete a sale |
| GET | `/api/khata/dashboard` | Bearer | Khata + shop snapshot |
| POST | `/api/khata/transcripts/analyze` | Bearer | Speech → ledger |
| GET/POST | `/api/khata/customers` | Bearer | List / create customers |
| POST | `/api/khata/entries` | Bearer | Manual entry |
| PATCH/DELETE | `/api/khata/entries/{id}` | Bearer | Edit / soft-delete (not sale-sourced) |

---

## Flutter client map

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Material 3 app, warm off-white theme, brand orange |
| `lib/constants.dart` | **Change `apiBaseUrl` here** for your machine |
| `screens/app_startup/` | Session restore |
| `screens/welcome_screen/` · `shop_profile_screen/` · `sign_in_screen/` · `verify_otp_screen/` | Auth |
| `screens/main_shell/` | Bottom nav: POS · Sales (invoice) · Inventory · Khata · More |
| `screens/pos_screen/` | Cart, scanner, checkout |
| `screens/scan_invoice_screen/` | Camera, Gemini result, handwriting |
| `screens/inventory_screen/` | Stock list |
| `screens/khata_screen/` | Dashboard, consent, voice status |
| `services/foreground_speech_service.dart` | Mic lifecycle + flush to API |
| `services/transcript_queue.dart` | SQLite outbox |

The app requests **camera**, **microphone**, and **internet**. Android allows cleartext HTTP so a LAN backend works during development (`usesCleartextTraffic`).

---

## Prerequisites

- **Python 3.11+**
- **PostgreSQL 14+** (async driver: `asyncpg`)
- **Flutter SDK** matching `udyam/pubspec.yaml` (`sdk: ^3.13.1`)
- **Android device or emulator** (camera and mic features are first-class; a physical phone is strongly preferred)
- A **Telegram bot token** (BotFather) and the shopkeeper’s numeric **chat ID**
- A **Gemini API key** (invoice + transcript analysis)

---

## Run the backend

```bash
cd backend
python -m venv .venv

# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# macOS / Linux
# source .venv/bin/activate

pip install -r requirements.txt
copy .env.example .env   # Windows: copy  |  Unix: cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL=postgresql+asyncpg://USER:PASSWORD@localhost:5432/dukaan_os
TELEGRAM_BOT_TOKEN=your-bot-token
JWT_SECRET=a-long-random-secret
GEMINI_API_KEY=your-gemini-key
GEMINI_MODEL=gemini-2.5-flash
```

Create the database (example):

```sql
CREATE DATABASE dukaan_os;
```

Start the API (default port **8000**):

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

`--host 0.0.0.0` is required so a phone on the same Wi-Fi can reach the laptop. Confirm with `GET http://localhost:8000/health` → `{"status":"ok"}`.

---

## Run the Android app

1. Point the client at your machine. In `udyam/lib/constants.dart`:

   ```dart
   static const String apiBaseUrl = 'http://192.168.x.x:8000';
   ```

   Use the laptop’s LAN IP, not `localhost` (on the phone, localhost is the phone). Emulator-to-host on Android is often `http://10.0.2.2:8000`.

2. Install and launch:

   ```bash
   cd udyam
   flutter pub get
   flutter run
   ```

3. On first signup, fill shop details and the Telegram **chat ID** (the bot must be able to message that chat). Request OTP, enter the code from Telegram, then use POS / invoice / inventory / khata.

### Telegram chat ID

Start a chat with your bot, then inspect updates (`getUpdates`) or use a helper bot that prints chat IDs. The value must match what you type in shop profile.

---

## Tests

```bash
# Backend (from backend/, venv on)
python -m unittest discover -s tests -v

# Flutter (from udyam/)
flutter test
```

Backend tests cover invoice JSON parsing, inventory name normalization, and khata/sales behavior. Flutter tests cover invoice/inventory models and khata voice buffering.

---

## Configuration cheat sheet

| Setting | Where | Notes |
| --- | --- | --- |
| API host | `udyam/lib/constants.dart` → `apiBaseUrl` | Must match `uvicorn` host/port |
| Database, JWT, Gemini, Telegram | `backend/.env` | Never commit `.env` |
| OTP lifetime | `OTP_EXPIRE_SECONDS` (default 300) | `backend/app/config.py` |
| JWT lifetime | `ACCESS_TOKEN_EXPIRE_MINUTES` (default 7 days) | Same file |
| Max invoice bytes | `MAX_INVOICE_IMAGE_BYTES` (default 10 MB) | Same file |
| Auto-create khata from speech | confidence ≥ 0.70 | `backend/app/services/khata.py` |

---

## Typical shop loop

```text
Set up shop + Telegram OTP
        ↓
Scan supplier bill → review → stock increases
        ↓
Scan barcodes at the counter → cash or credit bill → stock decreases
        ↓
(optional) Let the phone listen → spoken udhaar / payment lands in khata
        ↓
Open Khata / Inventory to confirm, not to re-enter
```

That loop is the product: **observe → understand → update → check**.

---

## License and status

Internal / personal project. The Flutter package is still named `udyam`; the product name in the UI is **DukaanOS**.
