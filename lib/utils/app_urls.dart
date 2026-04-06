class AppUrls {
  // static const String baseUrl = "https://zafgoal.onrender.com";
  static const String baseUrl = "http://31.97.130.35:3000";
  static const String createAccount = "$baseUrl/api/v1/user/register";
  static const String loginAccount = "$baseUrl/api/v1/user/login";
  static const String verifyOtp = "$baseUrl/api/v1/user/verify-registration-otp";
  static const String resendRegistrationOtp = "$baseUrl/api/v1/user/resend-registration-otp";
 
//  ? forgot password 
  static const String forgotpassword = "$baseUrl/api/v1/user/forgot-password";
  static const String forgotPasswordOtpVerify = "$baseUrl/api/v1/user/forgot-password-otp-verify";
  static const String resetPassword = "$baseUrl/api/v1/user/reset-password";

  // ? get categories
  static const String getAllCategories = "$baseUrl/api/v1/category/get-all-categories";
  static const String getProductByCategory = "$baseUrl/api/v1/product/category";
  static const String getAllProducts = "$baseUrl/api/v1/product/get-all-products";

// ? favrouties items
  static const String addToFavourites = "$baseUrl/api/v1/favorite/add";
  static const String getFavourites = "$baseUrl/api/v1/favorite/my-favorites?limit=100";
  static const String removeFavorites = "$baseUrl/api/v1/favorite/remove";

// ? address
  static const String addAddress = "$baseUrl/api/v1/address/addresses";
  static const String updateAddress = "$baseUrl/api/v1/address/addresses";
  static const String deleteAddress = "$baseUrl/api/v1/address/addresses";
  static const String getAddress = "$baseUrl/api/v1/address/addresses";
  
  
  // ? create order
  static const String createOrder = "$baseUrl/api/v1/payment/create-order";
  static const String processPayment = "$baseUrl/api/v1/payment/process";
  static const String confirmPayment = "$baseUrl/api/v1/order/check-payment-status";
  static const String getOrderHistory = "$baseUrl/api/v1/order/get-all-orders";

  // ? reviews
  static const String createReview = "$baseUrl/api/v1/review/create";
  static const String getProductReview = "$baseUrl/api/v1/review/product";
  static const String updateProductReview = "$baseUrl/api/v1/review/update";
  static const String deleteProductReview = "$baseUrl/api/v1/review/delete";

  // ? driver endpoints
  static const String getMyDeliveries = "$baseUrl/api/v1/order/my-deliveries";
  static const String getDriverStats = "$baseUrl/api/v1/order/driver-stats";
  static const String updateDeliveryStatus = "$baseUrl/api/v1/order/update-delivery-status";
  static const String submitWaterTest = "$baseUrl/api/v1/water-test/submit";
  static const String submitEodReport = "$baseUrl/api/v1/eod-report/submit";

  // ? water test / crate (customer-facing)
  static const String waterTestHistory = "$baseUrl/api/v1/water-test/history";
  static String pendingCrate(String orderId) => "$baseUrl/api/v1/water-test/pending-crate/$orderId";
  static String approveCrate(String orderId) => "$baseUrl/api/v1/water-test/approve-crate/$orderId";
  static String declineCrate(String orderId) => "$baseUrl/api/v1/water-test/decline-crate/$orderId";
  static String poolReport(String orderId) => "$baseUrl/api/v1/water-test/pool-report/$orderId";

  // ? fcm token
  static const String saveFcmToken = "$baseUrl/api/v1/user/fcm-token";

  // ? notifications
  static const String getNotifications = "$baseUrl/api/v1/notification";

  // ? Slider images
  static const String getSlider = "$baseUrl/api/v1/slider/active";

  // ? Cart sync
  static const String addToCart = "$baseUrl/api/v1/cart/add-to-cart";
  static const String clearCart = "$baseUrl/api/v1/cart/clear-cart";

  // ? Water Test Service
  static const String getWaterTestService = "$baseUrl/api/v1/cart/water-test-service";

  // ? Setup Profile (delivery safety + water setup)
  static const String getSetupProfile = "$baseUrl/api/v1/user/setup-profile";
  static const String saveSetupProfile = "$baseUrl/api/v1/user/setup-profile";

  // ? Get / Update user details
  static const String getUserDetails = "$baseUrl/api/v1/user/get-user-details";
  static const String updateUserDetails = "$baseUrl/api/v1/user/update-user-details";

  // ? Delete account
  static const String deleteAccount = "$baseUrl/api/v1/user/delete-account";

  // ? Onboarding
  static const String onboardingStatus = "$baseUrl/api/v1/user/onboarding/status";
  static const String onboardingComplete = "$baseUrl/api/v1/user/onboarding/complete";
  static const String onboardingReset = "$baseUrl/api/v1/user/onboarding/reset";
}