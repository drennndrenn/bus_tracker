# Firebase setup — Smart Bus Tracker Admin

Your Firebase CLI is logged in as **capumpue.jelou@dnsc.edu.ph**. Project creation from this machine may fail with an SSL error (`unable to verify the first certificate`). Create the project in the browser if needed.

## 1. Create Firebase project (Console)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. **Add project** → name e.g. `Smart Bus Tracker DDN`
3. Project ID example: `smart-bus-tracker-ddn` (must be globally unique — adjust if taken)
4. Enable **Authentication** → Email/Password sign-in
5. Create **Firestore Database** (production mode is fine; rules deploy below)
6. **Build** → add a **Web app** → copy the config keys

## 2. Configure admin web app

```bash
cd admin_web
copy .env.example .env
```

Paste your web app keys into `.env`:

```
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
...
```

## 3. Link Firebase CLI

```bash
cd firebase
firebase use --add
```

Select your project ID. Update `.firebaserc` if the ID differs from `smart-bus-tracker-ddn`.

## 4. Deploy rules & functions

```bash
cd firebase/functions
npm install
cd ..
firebase deploy --only firestore:rules,functions
```

## 5. Seed demo admins & sample data (required for login)

`auth/invalid-credential` means the demo users do not exist yet. Use **Option A** (easiest).

### Option A — Local seed script (recommended)

1. Firebase Console → **Project settings** → **Service accounts**
2. Click **Generate new private key** → save file as:
   `firebase/serviceAccountKey.json`
3. In terminal:

```powershell
cd firebase
$env:NODE_OPTIONS="--use-system-ca"
npm install
node scripts/seed-demo-admins.mjs
```

4. Sign in again at http://localhost:5174/login

### Option B — Cloud Function (after deploy)

```powershell
curl -X POST "https://us-central1-smart-bus-tracker-ddn.cloudfunctions.net/seedDemoEnvironment" -H "x-seed-key: bus-tracker-demo-2026"
```

### Option C — Manual (Firebase Console)

1. **Authentication** → **Users** → **Add user**
   - `superadmin@bustracker.demo` / `SuperAdmin123!`
   - `subadmin@bustracker.demo` / `SubAdmin123!`
2. Copy each user’s **User UID**
3. **Firestore** → collection `admins` → add document (document ID = UID):

| Field | Super admin doc | Sub admin doc |
|-------|-----------------|---------------|
| email | superadmin@bustracker.demo | subadmin@bustracker.demo |
| displayName | Super Admin | Bachelor Express Sub Admin |
| role | super_admin | sub_admin |
| companyId | null | dnsc-express |

4. Create collection `companies` → document `dnsc-express` with `name: Bachelor Express` (display name; document ID unchanged)

**Default fleet data (auto-seeded):** Signing in as sub admin loads **7 routes**, **7 buses**, and **42 fares** (same matrix as the mobile app `fare_data.dart`). Or run `node firebase/scripts/seed-demo-admins.mjs` with a service account key.

**Mobile app:** The Flutter routes screen reads fares from `companies/dnsc-express/fares` in Firestore (public read). After changing rules, deploy: `firebase deploy --only firestore:rules`. Pull-to-refresh on the Routes tab reloads live data.

### Demo logins (one login page, different dashboards)

| Role | Email | Password |
|------|--------|----------|
| **Super admin** | superadmin@bustracker.demo | SuperAdmin123! |
| **Sub admin** | subadmin@bustracker.demo | SubAdmin123! |

- Super admin → `/super` (companies, payment approval, stats)
- Sub admin → `/sub` (routes, buses, fares for **Bachelor Express** only)

## 6. Run admin dashboard locally

```bash
cd admin_web
npm install
npm run dev
```

Open http://localhost:5174

## 7. Optional: deploy hosting

```bash
cd admin_web
npm run build
cd ../firebase
firebase deploy --only hosting
```

---

## Architecture summary

- **One login page** (`/login`) for all admins
- After sign-in, app reads `admins/{uid}` in Firestore → `role` field
- `super_admin` → Super Admin Dashboard
- `sub_admin` → Sub Admin Dashboard (scoped by `companyId`)
- **Payment review** → super admin only (`payment_requests` collection + `reviewPaymentRequest` Cloud Function)

## Mobile app

The Flutter commuter app is unchanged. Connecting it to Firestore for live fares/routes is a separate step.
