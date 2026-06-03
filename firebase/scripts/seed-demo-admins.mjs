/**
 * Creates demo admin Auth users + Firestore data.
 *
 * 1. Firebase Console → Project settings → Service accounts → Generate new private key
 * 2. Save as firebase/serviceAccountKey.json (do not commit)
 * 3. Run: node scripts/seed-demo-admins.mjs
 */
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';
import { appendCompanyFleet, COMPANY_ID, COMPANY_NAME } from './bachelor-express-data.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const keyPath = join(__dirname, '..', 'serviceAccountKey.json');

if (!existsSync(keyPath)) {
  console.error(`
Missing firebase/serviceAccountKey.json

Download it:
  Firebase Console → Project settings → Service accounts
  → Generate new private key → save as firebase/serviceAccountKey.json

Then run again:
  cd firebase
  npm install firebase-admin
  node scripts/seed-demo-admins.mjs
`);
  process.exit(1);
}

const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const DEMO = {
  superAdmin: {
    email: 'superadmin@bustracker.demo',
    password: 'SuperAdmin123!',
    displayName: 'Super Admin',
  },
  subAdmin: {
    email: 'subadmin@bustracker.demo',
    password: 'SubAdmin123!',
    displayName: 'Bachelor Express Sub Admin',
  },
  company: { id: COMPANY_ID, name: COMPANY_NAME, region: 'Davao del Norte' },
};

async function ensureUser({ email, password, displayName }) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    return auth.createUser({ email, password, displayName, emailVerified: true });
  }
}

async function resetPassword(uid, password) {
  await auth.updateUser(uid, { password });
}

async function clearSubcollection(companyRef, name) {
  const snap = await companyRef.collection(name).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}

async function seedCompanyFleet(companyRef) {
  await clearSubcollection(companyRef, 'routes');
  await clearSubcollection(companyRef, 'buses');
  await clearSubcollection(companyRef, 'fares');
  const batch = db.batch();
  appendCompanyFleet(batch, companyRef, FieldValue);
  await batch.commit();
}

async function main() {
  console.log('Seeding demo admins for Smart Bus Tracker…\n');

  const superUser = await ensureUser(DEMO.superAdmin);
  const subUser = await ensureUser(DEMO.subAdmin);
  await resetPassword(superUser.uid, DEMO.superAdmin.password);
  await resetPassword(subUser.uid, DEMO.subAdmin.password);

  await db.collection('companies').doc(DEMO.company.id).set(
    {
      name: DEMO.company.name,
      region: DEMO.company.region,
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await db.collection('admins').doc(superUser.uid).set({
    email: DEMO.superAdmin.email,
    displayName: DEMO.superAdmin.displayName,
    role: 'super_admin',
    companyId: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  await db.collection('admins').doc(subUser.uid).set({
    email: DEMO.subAdmin.email,
    displayName: DEMO.subAdmin.displayName,
    role: 'sub_admin',
    companyId: DEMO.company.id,
    createdAt: FieldValue.serverTimestamp(),
  });

  const companyRef = db.collection('companies').doc(DEMO.company.id);
  await seedCompanyFleet(companyRef);
  console.log('Bachelor Express: 7 routes, 7 buses, 42 fares seeded.\n');

  const pending = await db
    .collection('payment_requests')
    .where('status', '==', 'pending')
    .limit(1)
    .get();
  if (pending.empty) {
    await db.collection('payment_requests').add({
      userEmail: 'commuter.demo@bustracker.ph',
      senderName: 'Juan Dela Cruz',
      amount: 99,
      plan: 'pro_monthly',
      status: 'pending',
      proofNote: 'GCash ref: DEMO1234',
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  console.log('Done!\n');
  console.log('Super admin:', DEMO.superAdmin.email, '/', DEMO.superAdmin.password);
  console.log('Sub admin:  ', DEMO.subAdmin.email, '/', DEMO.subAdmin.password);
  console.log('\nSign in at http://localhost:5174/login');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
