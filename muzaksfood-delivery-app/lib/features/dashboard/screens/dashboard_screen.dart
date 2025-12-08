// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:grocery_delivery_boy/common/providers/tracker_provider.dart';
import 'package:grocery_delivery_boy/common/providers/permission_handler_provider.dart';
import 'package:grocery_delivery_boy/features/order/providers/order_provider.dart';
import 'package:grocery_delivery_boy/features/profile/providers/profile_provider.dart';
import 'package:grocery_delivery_boy/helper/location_helper.dart';
import 'package:grocery_delivery_boy/helper/notification_helper.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/features/home/screens/home_screen.dart';
import 'package:grocery_delivery_boy/features/order/screens/order_history_screen.dart';
import 'package:grocery_delivery_boy/features/profile/screens/profile_screen.dart';
import 'package:grocery_delivery_boy/main.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  late List<Widget> _screens;
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    Provider.of<OrderProvider>(context, listen: false).getAllOrders();
    Provider.of<ProfileProvider>(context, listen: false).getUserInfo(context);

    _screens = [
      HomeScreen(),
      OrderHistoryScreen(),
      const ProfileScreen(),
    ];

    _listener = AppLifecycleListener(
      onPause: () async {
        debugPrint('---(state)---on pause------');
        final bool isPositionStreamActive = Provider.of<TrackerProvider>(context, listen: false).isPositionStreamActive;
        final currentLocationPermission = await Geolocator.checkPermission();
        if(isPositionStreamActive && currentLocationPermission == LocationPermission.always) {
          _startForegroundLocationUpdates();
        }
      },
      onResume: () async {
        debugPrint('---(state)---on onResume------');
        LocationPermission permission = await Geolocator.checkPermission();
        Provider.of<PermissionHandlerProvider>(context, listen: false).setLocationPermission(permission);

        
      },
      onRestart: () async {

        final permissionProvider = Provider.of<PermissionHandlerProvider>(context, listen: false);
        if(!permissionProvider.isDialogOpen){
          final currentLocationPermission = await Geolocator.checkPermission();
          final PermissionStatus notificationPermission = await Permission.notification.status;

          if(mounted){
            ///This Is for Location
            if(currentLocationPermission == LocationPermission.denied || currentLocationPermission == LocationPermission.deniedForever) {
              permissionProvider.setLocationPermission(LocationPermission.denied);
              permissionProvider.setLocationWarningShown(true);

            }else {
              if(currentLocationPermission != LocationPermission.always) {
                permissionProvider.setLocationPermission(LocationPermission.always);
                permissionProvider.setLocationWarningShown(true);
              }else{
                permissionProvider.setLocationWarningShown(false);
              }
            }

            ///This is for Notification
            if(notificationPermission.isGranted){
              permissionProvider.setNotificationWarningShown(false);
            }else{
              permissionProvider.setNotificationWarningShown(true);
            }
          }

          if(permissionProvider.isOpenSetting) {
            permissionProvider.setOpenSetting(false);
            _disableBatteryOptimization();
          }

          stopService();
        }
      },
    );

    Provider.of<OrderProvider>(Get.context!, listen: false).getOrdersCount().then((orderCount) async {
      final currentLocationPermission = await Geolocator.checkPermission();

      if ((orderCount?.outForDelivery ?? 0) > 0 && (currentLocationPermission != LocationPermission.denied && currentLocationPermission != LocationPermission.deniedForever)) {
        Provider.of<TrackerProvider>(Get.context!, listen: false).startListenCurrentLocation();
      } else if (orderCount != null && orderCount.outForDelivery != null && orderCount.outForDelivery! < 1) {
        Provider.of<TrackerProvider>(Get.context!, listen: false).stopListening();
      }
    });

    _onPermissionHandle();
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_pageIndex != 0) {
          _setPage(0);
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Theme.of(context).hintColor,
          backgroundColor: Theme.of(context).cardColor,
          showUnselectedLabels: true,
          currentIndex: _pageIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            _barItem(Icons.home, getTranslated('home', context), 0),
            _barItem(Icons.history, getTranslated('order_history', context), 1),
            _barItem(Icons.person, getTranslated('profile', context), 2),
          ],
          onTap: (int index) {
            _setPage(index);
          },
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: _screens.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _screens[index];
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem _barItem(IconData icon, String? label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(icon, color: index == _pageIndex ? Theme.of(context).primaryColor : Theme.of(context).hintColor, size: 20),
      label: label,
    );
  }

  void _setPage(int pageIndex) {
    setState(() {
      _pageController.jumpToPage(pageIndex);
      _pageIndex = pageIndex;
    });
  }

  Future<void> _onPermissionHandle() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final permissionProvider = Provider.of<PermissionHandlerProvider>(context, listen: false);
      final currentLocationPermission = await Geolocator.checkPermission();
      final PermissionStatus notificationPermission = await Permission.notification.status;

      ///This is for Location permission
      if (currentLocationPermission == LocationPermission.denied || currentLocationPermission == LocationPermission.deniedForever) {
        await _checkLocationPermission();

        if(mounted) {
          permissionProvider.setLocationWarningShown(true);
        }
      }else {
        if(currentLocationPermission != LocationPermission.always && mounted) {
          permissionProvider.setLocationWarningShown(true);
          permissionProvider.setLocationPermission(LocationPermission.always);
        }
      }

      ///This is for Notification
      if(notificationPermission.isGranted){
        permissionProvider.setNotificationWarningShown(false);
      }else{
        permissionProvider.setNotificationWarningShown(true);
      }

    });
  }

  Future<void> _checkLocationPermission() async {
    final permissionProvider = Provider.of<PermissionHandlerProvider>(context, listen: false);
    permissionProvider.setDialogOpen(true);
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          insetPadding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: EdgeInsets.zero,
          actionsPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault).copyWith(bottom: Dimensions.paddingSizeExtraSmall, top: Dimensions.paddingSizeExtraSmall),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: ()async {
                  Navigator.of(context).pop();
                  permissionProvider.setDialogOpen(false);
                  _disableBatteryOptimization();
                },
                child: Container(
                  margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha: 0.05),
                      shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.clear, size: Dimensions.paddingSizeDefault),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge).copyWith(top: 0),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  getTranslated('location_access_needed', context),
                  style: rubikBold.copyWith(color: Theme.of(context).textTheme.titleSmall?.color),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(
                  getTranslated('to_provide_accurate_delivery_tracking', context),
                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Text(
                  getTranslated('why_we_need_it', context),
                  style: rubikMedium.copyWith(color: Theme.of(context).textTheme.titleSmall?.color),
                ),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin:const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    height: 7,width: 7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.all(Radius.circular(100)),
                    ),
                  ),

                  Expanded(child: Text(
                    getTranslated('show_your_live_location_on_the_map', context),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7)),
                  )),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin:const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    height: 7,width: 7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.all(Radius.circular(100)),
                    ),
                  ),

                  Expanded(child: Text(
                    getTranslated('provide_accurate_delivery_eta', context),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7)),
                  )),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin:const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    height: 7,width: 7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.all(Radius.circular(100)),
                    ),
                  ),

                  Expanded(child: Text(
                    getTranslated('ensure_seamless_tracking_even_in', context),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7)),
                  )),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    margin:const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    height: 7,width: 7,
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.all(Radius.circular(100)),
                    ),
                  ),

                  Expanded(child: Text(getTranslated('improve_delivery_efficiency', context),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7)),
                  )),
                ]),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Text(
                  getTranslated('note', context),
                  style: rubikMedium.copyWith(color: Theme.of(context).textTheme.titleSmall?.color),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(
                  getTranslated('your_location_is_only_used_for', context),
                  style: rubikRegular.copyWith(color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.7), fontSize: Dimensions.fontSizeSmall),
                ),


              ]),
            ),
          ]),
          actions: [
            if(!Platform.isIOS)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  permissionProvider.setDialogOpen(false);
                  _disableBatteryOptimization();
                },
                child: Text(getTranslated('cancel', context), style: rubikRegular.copyWith(color: Theme.of(context).primaryColor)),
              ),

            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                permissionProvider.setDialogOpen(false);
                await LocationHelper.checkPermission(context);
                _disableBatteryOptimization();

              },
              child: Text(getTranslated('next', context), style: rubikRegular.copyWith(color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future _disableBatteryOptimization() async {
    final permissionHandlerProvider = Provider.of<PermissionHandlerProvider>(context, listen: false);

    bool isDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;

    bool isAlwaysAllowLocation = await Geolocator.checkPermission() == LocationPermission.always;
    final NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();

    Future.delayed(const Duration(seconds: 1)).then((value){
      if (!isDisabled &&
          (isAlwaysAllowLocation || settings.authorizationStatus == AuthorizationStatus.authorized)
          && !permissionHandlerProvider.isDialogOpen) {
        DisableBatteryOptimization.showDisableBatteryOptimizationSettings();

      }
    });

  }

  void _startForegroundLocationUpdates() async {
    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'grofresh',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        onlyAlertOnce: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // Start the foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: getTranslated('location_tracking', context),
      notificationText: getTranslated('tracking_your_location_on_background', context),
      // callback: Provider.of<TrackerProvider>(context, listen: false).startListening,
    );
  }
}
