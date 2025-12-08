import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/common/models/config_model.dart';
import 'package:grocery_delivery_boy/common/models/notification_body.dart';
import 'package:grocery_delivery_boy/features/chat/screens/chat_screen.dart';
import 'package:grocery_delivery_boy/features/order/providers/order_provider.dart';
import 'package:grocery_delivery_boy/features/order/screens/order_details_screen.dart';
import 'package:grocery_delivery_boy/helper/maintenance_helper.dart';
import 'package:grocery_delivery_boy/main.dart';
import 'package:grocery_delivery_boy/utill/app_constants.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/features/auth/providers/auth_provider.dart';
import 'package:grocery_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/features/maintainance/screens/maintenance_screen.dart';
import 'package:grocery_delivery_boy/features/dashboard/screens/dashboard_screen.dart';
import 'package:grocery_delivery_boy/features/language/screens/choose_language_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  NotificationBody? notificationBody;



  @override
  void initState() {
    super.initState();

    triggerFirebaseNotification();

    _onRoute();
  }


  Future<void> triggerFirebaseNotification() async {
    try {
      final RemoteMessage? remoteMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (remoteMessage != null) {
        notificationBody = NotificationBody.fromJson(remoteMessage.data);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(Images.logo, width: 120)),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            Text(AppConstants.appName, style: rubikBold.copyWith(
              fontSize: 25, color: Theme.of(context).primaryColor,
            ), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _onRoute() {

    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    splashProvider.initSharedData();
    splashProvider.initConfig().then((bool isSuccess) {
      if (isSuccess) {

        final ConfigModel? configModel = splashProvider.configModel;

        if(MaintenanceHelper.isMaintenanceModeEnable(configModel) && MaintenanceHelper.isDeliveryMaintenanceEnable(configModel)) {
          Navigator.pushReplacement(Get.context!, MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
        }else{
          Timer(const Duration(seconds: 1), () async {
            if(notificationBody != null){
              final int? orderId = notificationBody?.orderId;
              final String? type = notificationBody?.type;

              if(orderId != null && type == 'message'){
                final OrderProvider orderProvider = Provider.of<OrderProvider>(Get.context!, listen: false);
                await orderProvider.getOrderModel(orderId.toString());
                Get.navigator!.pushReplacement(MaterialPageRoute(builder: (context) =>
                    ChatScreen(orderModel: orderProvider.currentOrderModel)),
                );
              } else if(orderId != null && type == 'order'){
                Get.navigator!.pushReplacement(MaterialPageRoute(builder: (context) =>
                    OrderDetailsScreen(orderId: orderId)),
                );
              }
            }
            else if (Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
              Provider.of<AuthProvider>(context, listen: false).updateToken();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChooseLanguageScreen()));
            }

          });
        }

      }
    });
  }

}
