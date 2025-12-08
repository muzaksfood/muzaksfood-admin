import 'package:grocery_delivery_boy/features/language/domain/models/language_model.dart';
import 'package:grocery_delivery_boy/utill/images.dart';

class AppConstants {
  static const String appName = 'MuzaksFood Delivery Man';
  static const double appVersion = 7.9; /// flutter sdk 3.38.0
  static const String fontFamily = 'Rubik';
  static const String baseUrl = 'YOUR_BASE_URL_HERE';
  static const String profileUri = '/api/v1/delivery-man/profile?token=';
  static const String configUri = '/api/v1/config';
  static const String loginUri = '/api/v1/auth/delivery-man/login';
  static const String notificationUri = '/api/v1/notifications';
  static const String currentOrdersUri = '/api/v1/delivery-man/current-orders?token=';
  static const String orderDetailsUri = '/api/v1/delivery-man/order-details?token=';
  static const String orderHistoryUri = '/api/v1/delivery-man/all-orders?token=';
  static const String recordLocationUri = '/api/v1/delivery-man/record-location-data';
  static const String updateOrderStatusUri = '/api/v1/delivery-man/update-order-status';
  static const String updatePaymentStatusUri = '/api/v1/delivery-man/update-payment-status';
  static const String tokenUri = '/api/v1/delivery-man/update-fcm-token';
  static const String getMessageUri = '/api/v1/delivery-man/message/get-message';
  static const String sendMessageUri = '/api/v1/delivery-man/message/send/deliveryman';
  static const String register = '/api/v1/auth/delivery-man/register';
  static const String getOrderModel = '/api/v1/delivery-man/order-model?token=';
  static const String changeLanguage = '/api/v1/delivery-man/change-language';
  static const String ordersCountUri = '/api/v1/delivery-man/orders-count?token=';
  static const String accountPermanentDelete = '/api/v1/delivery-man/delete-account?token=';



  // Shared Key
  static const String theme = 'theme';
  static const String token = 'token';
  static const String countryCode = 'countryCode';
  static const String languageCode = 'languageCode';
  static const String cartList = 'cartList';
  static const String userPassword = 'userPassword';
  static const String userEmail = 'userEmail';
  static const String topic = 'deliveryman';
  static const String orderId = 'order_id';

  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.unitedKingdom, languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(imageUrl: Images.arabic, languageName: 'Arabic', countryCode: 'SA', languageCode: 'ar'),
  ];
}
