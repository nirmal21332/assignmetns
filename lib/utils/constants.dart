class AppConstants {
  static const String appName = 'Task Manager';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';

  // API
  static const String quoteApiUrl = 'https://api.quotable.io/random';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 30;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;

  // UI
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double inputBorderRadius = 12.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
}