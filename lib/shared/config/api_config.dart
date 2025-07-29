class ApiConfig {
  // Development URLs (for Android emulator)
  static const String devBaseUrl = 'http://10.0.2.2:5070';
  
  // Production URLs (for real devices)
  static const String prodBaseUrl = 'http://192.168.0.123:5070';
  
  // Current environment - change this to switch between dev/prod
  static const bool isDevelopment = true;
  
  // Get the appropriate base URL based on environment
  static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;
  
  // API endpoints
  static String get expertAuth => '$baseUrl/api/expertauth';
  static String get expertWallet => '$baseUrl/api/expertwallet';
  static String get session => '$baseUrl/api/session';
  static String get zoomVideo => '$baseUrl/api/zoomVideo';
  
  // Specific endpoints
  static String expertAuthById(String id) => '$expertAuth/$id';
  static String walletBalances() => '$expertWallet/balances';
  static String walletSpending() => '$expertWallet/spending/pay';
  static String expertToExpertSession() => '$session/experttoexpertsession';
  static String zoomVideoToken() => '$zoomVideo/generate-expert-video-token';
  static String zoomVideoSession(String sessionId) => '$zoomVideo/get-session/$sessionId';
  static String zoomVideoUserJoined(String sessionId) => '$zoomVideo/user-joined/$sessionId';
} 