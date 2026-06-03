import { collection, doc, getDocs, serverTimestamp, writeBatch } from 'firebase/firestore';
import { db } from './firebase';

/** Firestore company id for Bachelor Express */
export const BACHELOR_EXPRESS_COMPANY_ID = 'dnsc-express';

export const LOCATIONS = [
  'Tagum City',
  'Panabo City',
  'Carmen',
  'Sto. Tomas',
  'Kapalong',
  'New Corella',
  'Asuncion',
] as const;

/** Mirrors mobile_app/lib/features/routes/data/fare_data.dart */
export const FARE_MATRIX: Record<string, { destination: string; amount: number }[]> = {
  'Tagum City': [
    { destination: 'Panabo City', amount: 50 },
    { destination: 'Carmen', amount: 35 },
    { destination: 'Sto. Tomas', amount: 50 },
    { destination: 'Kapalong', amount: 50 },
    { destination: 'New Corella', amount: 40 },
    { destination: 'Asuncion', amount: 30 },
  ],
  'Panabo City': [
    { destination: 'Tagum City', amount: 50 },
    { destination: 'Carmen', amount: 35 },
    { destination: 'Sto. Tomas', amount: 60 },
    { destination: 'Kapalong', amount: 70 },
    { destination: 'New Corella', amount: 50 },
    { destination: 'Asuncion', amount: 70 },
  ],
  Carmen: [
    { destination: 'Tagum City', amount: 40 },
    { destination: 'Panabo City', amount: 35 },
    { destination: 'Sto. Tomas', amount: 40 },
    { destination: 'Kapalong', amount: 55 },
    { destination: 'New Corella', amount: 55 },
    { destination: 'Asuncion', amount: 60 },
  ],
  'Sto. Tomas': [
    { destination: 'Tagum City', amount: 50 },
    { destination: 'Panabo City', amount: 60 },
    { destination: 'Carmen', amount: 40 },
    { destination: 'Kapalong', amount: 30 },
    { destination: 'New Corella', amount: 28 },
    { destination: 'Asuncion', amount: 40 },
  ],
  Kapalong: [
    { destination: 'Tagum City', amount: 50 },
    { destination: 'Panabo City', amount: 70 },
    { destination: 'Carmen', amount: 40 },
    { destination: 'Sto. Tomas', amount: 35 },
    { destination: 'New Corella', amount: 45 },
    { destination: 'Asuncion', amount: 30 },
  ],
  'New Corella': [
    { destination: 'Tagum City', amount: 40 },
    { destination: 'Panabo City', amount: 65 },
    { destination: 'Carmen', amount: 30 },
    { destination: 'Sto. Tomas', amount: 28 },
    { destination: 'Kapalong', amount: 45 },
    { destination: 'Asuncion', amount: 35 },
  ],
  Asuncion: [
    { destination: 'Tagum City', amount: 55 },
    { destination: 'Panabo City', amount: 75 },
    { destination: 'Carmen', amount: 45 },
    { destination: 'Sto. Tomas', amount: 40 },
    { destination: 'Kapalong', amount: 30 },
    { destination: 'New Corella', amount: 35 },
  ],
};

/** One bus per destination (7 total) */
export const DEMO_BUS_PLATES = [
  'NAA 4521',
  'TVB 8834',
  'KXY 2901',
  'DDE 7742',
  'PQM 1189',
  'RRN 6603',
  'STX 3490',
];

const EXPECTED_FARE_COUNT = Object.values(FARE_MATRIX).reduce((n, rows) => n + rows.length, 0);

async function clearSubcollection(companyId: string, name: 'routes' | 'buses' | 'fares') {
  const snap = await getDocs(collection(db, 'companies', companyId, name));
  if (snap.empty) return;
  const batch = writeBatch(db);
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
}

function isFleetExact(
  routes: number,
  buses: number,
  fares: number,
): boolean {
  return (
    routes === LOCATIONS.length &&
    buses === LOCATIONS.length &&
    fares === EXPECTED_FARE_COUNT
  );
}

export async function seedBachelorExpressIfEmpty(companyId: string): Promise<boolean> {
  const companyRef = doc(db, 'companies', companyId);
  const [routesSnap, busesSnap, faresSnap] = await Promise.all([
    getDocs(collection(companyRef, 'routes')),
    getDocs(collection(companyRef, 'buses')),
    getDocs(collection(companyRef, 'fares')),
  ]);

  if (isFleetExact(routesSnap.size, busesSnap.size, faresSnap.size)) {
    return false;
  }

  await Promise.all([
    clearSubcollection(companyId, 'routes'),
    clearSubcollection(companyId, 'buses'),
    clearSubcollection(companyId, 'fares'),
  ]);

  const batch = writeBatch(db);
  const ts = serverTimestamp();

  LOCATIONS.forEach((origin, index) => {
    const destination = LOCATIONS[(index + 1) % LOCATIONS.length];
    const routeRef = doc(collection(companyRef, 'routes'));
    batch.set(routeRef, {
      name: `${origin} – ${destination}`,
      origin,
      destination,
      status: 'active',
      updatedAt: ts,
    });

    const busRef = doc(collection(companyRef, 'buses'));
    batch.set(busRef, {
      plateNumber: DEMO_BUS_PLATES[index],
      routeLabel: origin,
      status: 'active',
      updatedAt: ts,
    });
  });

  for (const [origin, rows] of Object.entries(FARE_MATRIX)) {
    for (const { destination, amount } of rows) {
      const fareRef = doc(collection(companyRef, 'fares'));
      batch.set(fareRef, {
        origin,
        destination,
        amount,
        currency: 'PHP',
        updatedAt: ts,
      });
    }
  }

  await batch.commit();
  return true;
}
