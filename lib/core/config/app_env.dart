class AppEnv {
  // App Info
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'Hygiene Portal');
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  // Supabase Database & Backend Settings
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Authentication & Security
  static const String authTokenKey = String.fromEnvironment('AUTH_TOKEN_KEY', defaultValue: 'hygiene_auth_token');
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '',
  );
  static const String googleClientIdAndroid = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
    defaultValue: '',
  );
  static const String googleClientIdIos = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_IOS',
    defaultValue: '',
  );

  // GPS & Location Thresholds
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  static final double defaultLatitude = double.parse(
    const String.fromEnvironment('DEFAULT_LATITUDE', defaultValue: '3.1466'),
  );
  static final double defaultLongitude = double.parse(
    const String.fromEnvironment('DEFAULT_LONGITUDE', defaultValue: '101.6958'),
  );
  static final double gpsAccuracyThresholdMeters = double.parse(
    const String.fromEnvironment('GPS_ACCURACY_THRESHOLD_METERS', defaultValue: '150.0'),
  );

  // Storage & Media Bucket Limits
  static const String storageBucketName = String.fromEnvironment(
    'STORAGE_BUCKET_NAME',
    defaultValue: 'hygiene-proofs',
  );
  static const int maxPhotoUploadSizeMb = int.fromEnvironment('MAX_PHOTO_UPLOAD_SIZE_MB', defaultValue: 10);
}
