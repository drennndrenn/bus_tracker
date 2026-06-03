import 'fare_models.dart';

/// Offline fallback when Firestore is unavailable (matches seeded admin data).
const fallbackFareData = <String, List<FareItem>>{
  'Tagum City': [
    FareItem(destination: 'Panabo City', fare: 50),
    FareItem(destination: 'Carmen', fare: 35),
    FareItem(destination: 'Sto. Tomas', fare: 50),
    FareItem(destination: 'Kapalong', fare: 50),
    FareItem(destination: 'New Corella', fare: 40),
    FareItem(destination: 'Asuncion', fare: 30),
  ],
  'Panabo City': [
    FareItem(destination: 'Tagum City', fare: 50),
    FareItem(destination: 'Carmen', fare: 35),
    FareItem(destination: 'Sto. Tomas', fare: 60),
    FareItem(destination: 'Kapalong', fare: 70),
    FareItem(destination: 'New Corella', fare: 50),
    FareItem(destination: 'Asuncion', fare: 70),
  ],
  'Carmen': [
    FareItem(destination: 'Tagum City', fare: 40),
    FareItem(destination: 'Panabo City', fare: 35),
    FareItem(destination: 'Sto. Tomas', fare: 40),
    FareItem(destination: 'Kapalong', fare: 55),
    FareItem(destination: 'New Corella', fare: 55),
    FareItem(destination: 'Asuncion', fare: 60),
  ],
  'Sto. Tomas': [
    FareItem(destination: 'Tagum City', fare: 50),
    FareItem(destination: 'Panabo City', fare: 60),
    FareItem(destination: 'Carmen', fare: 40),
    FareItem(destination: 'Kapalong', fare: 30),
    FareItem(destination: 'New Corella', fare: 28),
    FareItem(destination: 'Asuncion', fare: 40),
  ],
  'Kapalong': [
    FareItem(destination: 'Tagum City', fare: 50),
    FareItem(destination: 'Panabo City', fare: 70),
    FareItem(destination: 'Carmen', fare: 40),
    FareItem(destination: 'Sto. Tomas', fare: 35),
    FareItem(destination: 'New Corella', fare: 45),
    FareItem(destination: 'Asuncion', fare: 30),
  ],
  'New Corella': [
    FareItem(destination: 'Tagum City', fare: 40),
    FareItem(destination: 'Panabo City', fare: 65),
    FareItem(destination: 'Carmen', fare: 30),
    FareItem(destination: 'Sto. Tomas', fare: 28),
    FareItem(destination: 'Kapalong', fare: 45),
    FareItem(destination: 'Asuncion', fare: 35),
  ],
  'Asuncion': [
    FareItem(destination: 'Tagum City', fare: 55),
    FareItem(destination: 'Panabo City', fare: 75),
    FareItem(destination: 'Carmen', fare: 45),
    FareItem(destination: 'Sto. Tomas', fare: 40),
    FareItem(destination: 'Kapalong', fare: 30),
    FareItem(destination: 'New Corella', fare: 35),
  ],
};
