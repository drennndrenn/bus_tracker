const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

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
  company: {
    id: 'dnsc-express',
    name: 'Bachelor Express',
    region: 'Davao del Norte',
  },
};

const LOCATIONS = [
  'Tagum City',
  'Panabo City',
  'Carmen',
  'Sto. Tomas',
  'Kapalong',
  'New Corella',
  'Asuncion',
];

const FARE_MATRIX = {
  'Tagum City': [
    ['Panabo City', 50],
    ['Carmen', 35],
    ['Sto. Tomas', 50],
    ['Kapalong', 50],
    ['New Corella', 40],
    ['Asuncion', 30],
  ],
  'Panabo City': [
    ['Tagum City', 50],
    ['Carmen', 35],
    ['Sto. Tomas', 60],
    ['Kapalong', 70],
    ['New Corella', 50],
    ['Asuncion', 70],
  ],
  Carmen: [
    ['Tagum City', 40],
    ['Panabo City', 35],
    ['Sto. Tomas', 40],
    ['Kapalong', 55],
    ['New Corella', 55],
    ['Asuncion', 60],
  ],
  'Sto. Tomas': [
    ['Tagum City', 50],
    ['Panabo City', 60],
    ['Carmen', 40],
    ['Kapalong', 30],
    ['New Corella', 28],
    ['Asuncion', 40],
  ],
  Kapalong: [
    ['Tagum City', 50],
    ['Panabo City', 70],
    ['Carmen', 40],
    ['Sto. Tomas', 35],
    ['New Corella', 45],
    ['Asuncion', 30],
  ],
  'New Corella': [
    ['Tagum City', 40],
    ['Panabo City', 65],
    ['Carmen', 30],
    ['Sto. Tomas', 28],
    ['Kapalong', 45],
    ['Asuncion', 35],
  ],
  Asuncion: [
    ['Tagum City', 55],
    ['Panabo City', 75],
    ['Carmen', 45],
    ['Sto. Tomas', 40],
    ['Kapalong', 30],
    ['New Corella', 35],
  ],
};

const DEMO_BUS_PLATES = [
  'NAA 4521',
  'TVB 8834',
  'KXY 2901',
  'DDE 7742',
  'PQM 1189',
  'RRN 6603',
  'STX 3490',
];

async function clearSubcollection(companyRef, name) {
  const snap = await companyRef.collection(name).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}

async function ensureAuthUser({ email, password, displayName }) {
  try {
    const existing = await auth.getUserByEmail(email);
    return existing;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    return auth.createUser({ email, password, displayName, emailVerified: true });
  }
}

exports.seedDemoEnvironment = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Use POST');
    return;
  }

  const seedKey = req.get('x-seed-key');
  if (seedKey !== 'bus-tracker-demo-2026') {
    res.status(403).json({ error: 'Invalid seed key' });
    return;
  }

  try {
    const superUser = await ensureAuthUser(DEMO.superAdmin);
    const subUser = await ensureAuthUser(DEMO.subAdmin);

    const companyRef = db.collection('companies').doc(DEMO.company.id);
    await companyRef.set(
      {
        name: DEMO.company.name,
        region: DEMO.company.region,
        status: 'active',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await db.collection('admins').doc(superUser.uid).set({
      email: DEMO.superAdmin.email,
      displayName: DEMO.superAdmin.displayName,
      role: 'super_admin',
      companyId: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('admins').doc(subUser.uid).set({
      email: DEMO.subAdmin.email,
      displayName: DEMO.subAdmin.displayName,
      role: 'sub_admin',
      companyId: DEMO.company.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await Promise.all([
      clearSubcollection(companyRef, 'routes'),
      clearSubcollection(companyRef, 'buses'),
      clearSubcollection(companyRef, 'fares'),
    ]);

    const batch = db.batch();
    const ts = admin.firestore.FieldValue.serverTimestamp();

    LOCATIONS.forEach((origin, index) => {
      const destination = LOCATIONS[(index + 1) % LOCATIONS.length];
      batch.set(companyRef.collection('routes').doc(), {
        name: `${origin} – ${destination}`,
        origin,
        destination,
        status: 'active',
        updatedAt: ts,
      });
      batch.set(companyRef.collection('buses').doc(), {
        plateNumber: DEMO_BUS_PLATES[index],
        routeLabel: origin,
        status: 'active',
        updatedAt: ts,
      });
    });

    for (const [origin, rows] of Object.entries(FARE_MATRIX)) {
      for (const [destination, amount] of rows) {
        batch.set(companyRef.collection('fares').doc(), {
          origin,
          destination,
          amount,
          currency: 'PHP',
          updatedAt: ts,
        });
      }
    }

    await batch.commit();

    await db.collection('payment_requests').add({
      userEmail: 'commuter.demo@bustracker.ph',
      senderName: 'Juan Dela Cruz',
      amount: 99,
      plan: 'pro_monthly',
      status: 'pending',
      proofNote: 'GCash ref: DEMO1234',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.json({
      ok: true,
      message: 'Demo environment seeded',
      credentials: {
        superAdmin: DEMO.superAdmin,
        subAdmin: DEMO.subAdmin,
      },
      companyId: DEMO.company.id,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

const PRO_MONTHLY_AMOUNT = 99;
const PRO_PLAN_ID = 'pro_monthly';
const MAX_PROOF_BASE64_LENGTH = 900000;

async function assertCommuter(uid) {
  const adminSnap = await db.collection('admins').doc(uid).get();
  if (adminSnap.exists) {
    throw new functions.https.HttpsError('permission-denied', 'Admin accounts cannot use commuter flows');
  }
}

exports.registerCommuter = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  await assertCommuter(context.auth.uid);

  const displayName = String(data.displayName || '').trim();
  if (displayName.length < 2) {
    throw new functions.https.HttpsError('invalid-argument', 'Display name is required');
  }

  const email = context.auth.token.email || '';
  const ref = db.collection('commuters').doc(context.auth.uid);

  await ref.set(
    {
      email,
      displayName,
      subscriptionStatus: 'free',
      activePlan: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true };
});

exports.submitPaymentRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  await assertCommuter(context.auth.uid);

  const senderName = String(data.senderName || '').trim();
  const amount = Number(data.amount);
  const plan = String(data.plan || '');
  const proofImageBase64 = String(data.proofImageBase64 || '');
  const proofNote = String(data.proofNote || '').trim();

  if (senderName.length < 2) {
    throw new functions.https.HttpsError('invalid-argument', 'Sender name is required');
  }
  if (plan !== PRO_PLAN_ID || amount !== PRO_MONTHLY_AMOUNT) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid plan or amount');
  }
  if (!proofImageBase64 || proofImageBase64.length > MAX_PROOF_BASE64_LENGTH) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Payment proof image is required and must be under size limit',
    );
  }

  const commuterRef = db.collection('commuters').doc(context.auth.uid);
  const commuterSnap = await commuterRef.get();
  if (!commuterSnap.exists) {
    throw new functions.https.HttpsError('failed-precondition', 'Commuter profile not found');
  }

  const status = commuterSnap.data().subscriptionStatus;
  if (status === 'pro') {
    throw new functions.https.HttpsError('already-exists', 'Pro subscription is already active');
  }
  if (status === 'pending') {
    throw new functions.https.HttpsError('already-exists', 'A payment is already pending review');
  }

  const pendingSnap = await db
    .collection('payment_requests')
    .where('userId', '==', context.auth.uid)
    .where('status', '==', 'pending')
    .limit(1)
    .get();

  if (!pendingSnap.empty) {
    throw new functions.https.HttpsError('already-exists', 'A payment is already pending review');
  }

  const email = context.auth.token.email || commuterSnap.data().email || '';
  const paymentRef = await db.collection('payment_requests').add({
    userId: context.auth.uid,
    userEmail: email,
    senderName,
    amount,
    plan,
    status: 'pending',
    proofImageBase64,
    proofNote: proofNote || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await commuterRef.set(
    {
      subscriptionStatus: 'pending',
      activePlan: plan,
      pendingPaymentId: paymentRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { ok: true, requestId: paymentRef.id };
});

exports.reviewPaymentRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }

  const adminSnap = await db.collection('admins').doc(context.auth.uid).get();
  if (!adminSnap.exists || adminSnap.data().role !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Super admin only');
  }

  const { requestId, decision, rejectReason } = data;
  if (!requestId || !['approved', 'rejected'].includes(decision)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid review payload');
  }

  const ref = db.collection('payment_requests').doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'Payment request not found');
  }

  const payment = snap.data();
  if (payment.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'Payment was already reviewed');
  }

  const userId = payment.userId;
  if (!userId) {
    throw new functions.https.HttpsError('failed-precondition', 'Payment has no linked commuter');
  }

  const commuterRef = db.collection('commuters').doc(userId);
  const commuterUpdate =
    decision === 'approved'
      ? {
          subscriptionStatus: 'pro',
          activePlan: payment.plan || PRO_PLAN_ID,
          proActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
          pendingPaymentId: null,
          rejectReason: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }
      : {
          subscriptionStatus: 'free',
          activePlan: null,
          pendingPaymentId: null,
          rejectReason: rejectReason || 'Payment could not be verified',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

  await db.runTransaction(async (tx) => {
    tx.update(ref, {
      status: decision,
      rejectReason: decision === 'rejected' ? rejectReason || 'Rejected by admin' : null,
      reviewedBy: context.auth.uid,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(commuterRef, commuterUpdate, { merge: true });
  });

  return { ok: true, status: decision };
});
