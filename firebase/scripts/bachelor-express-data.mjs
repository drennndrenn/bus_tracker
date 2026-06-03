/** Shared seed data — mirrors mobile_app fare_data.dart */
export const COMPANY_ID = 'dnsc-express';
export const COMPANY_NAME = 'Bachelor Express';

export const LOCATIONS = [
  'Tagum City',
  'Panabo City',
  'Carmen',
  'Sto. Tomas',
  'Kapalong',
  'New Corella',
  'Asuncion',
];

export const FARE_MATRIX = {
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

export const DEMO_BUS_PLATES = [
  'NAA 4521',
  'TVB 8834',
  'KXY 2901',
  'DDE 7742',
  'PQM 1189',
  'RRN 6603',
  'STX 3490',
];

export function appendCompanyFleet(batch, companyRef, FieldValue) {
  const ts = FieldValue.serverTimestamp();
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
}
