// Fare models and offline fallback. Live data comes from [CompanyFareRepository].
export 'fare_models.dart';
export 'fare_fallback_data.dart' show fallbackFareData;
export 'company_fare_repository.dart'
    show CompanyFareRepository, kDefaultCompanyId;
