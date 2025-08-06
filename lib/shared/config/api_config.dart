class ApiConfig {
  // Backend base URL - using the correct production URL
  static const String baseUrl = 'https://amd-api.code4bharat.com';
  
  // API endpoints - Updated to match backend routes
  static String get expertAuth => '$baseUrl/api/expertauth';
  static String get userAuth => '$baseUrl/api/userauth';
  static String get expertToExpertSession => '$baseUrl/api/experttoexpertsession'; // Fixed: was /api/experttoexpertsession
  static String get userToExpertSession => '$baseUrl/api/usertoexpertsession';
  static String get session => '$baseUrl/api/session';
  static String get zoomVideo => '$baseUrl/api/zoomVideo';
  static String get expertWallet => '$baseUrl/api/expertwallet';
  static String get userWallet => '$baseUrl/api/userwallet';
  static String get chat => '$baseUrl/api/chatbot';
  static String get ratings => '$baseUrl/api/ratings';
  static String get support => '$baseUrl/api/support';
  static String get giftCard => '$baseUrl/api/giftcard';
  static String get freeSession => '$baseUrl/api/freesession';
  static String get withdrawal => '$baseUrl/api/withdrawal';
  static String get expertWithdrawal => '$baseUrl/api/expertwithdrawal';
  
  // Specific endpoints - Updated to match backend routes
  static String expertSessionDetails(String sessionId) => '$expertToExpertSession/details/$sessionId';
  static String expertGenerateVideoAuth() => '$expertToExpertSession/generate-video-sdk-auth';
  static String userSessionDetails(String sessionId) => '$userToExpertSession/user-session-details/$sessionId';
  static String userGenerateVideoAuth() => '$userToExpertSession/generate-user-video-auth';
  static String userCompleteSession(String sessionId) => '$userToExpertSession/complete-user-session/$sessionId';
  static String expertSessions() => '$expertToExpertSession/getexpertsession'; // Fixed: removed expertId parameter and updated endpoint
  static String zoomVideoToken() => '$zoomVideo/generate-expert-video-token';
  static String zoomVideoSession(String sessionId) => '$zoomVideo/get-session/$sessionId';
  static String zoomVideoUserJoined(String sessionId) => '$zoomVideo/user-joined/$sessionId';
  static String expertWalletBalances() => '$expertWallet/balances';
  static String expertWalletSpending() => '$expertWallet/spending/pay';
  static String userWalletBalances() => '$userWallet/balances';
  static String countries() => '$baseUrl/api/countries';
} 