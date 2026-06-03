# Smart Bus Tracker

- **`mobile_app/`** — Flutter commuter app (Android / emulator)
- **`admin_web/`** — Web admin dashboard (super admin + sub admin)
- **`firebase/`** — Firestore rules, Cloud Functions, hosting config

## Commuter app

```bash
cd mobile_app
flutter pub get
flutter run
```

## Admin dashboard

See **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** for Firebase project creation, deploy, and demo accounts.

```bash
cd admin_web
npm install
npm run dev
```

One login page; role in Firestore routes to **Super Admin** or **Sub Admin** dashboard.
