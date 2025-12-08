import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/common/providers/permission_handler_provider.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_pop_scope_widget.dart';
import 'package:grocery_delivery_boy/features/home/widgets/location_permission_widget.dart';
import 'package:grocery_delivery_boy/features/home/widgets/order_widget.dart';
import 'package:grocery_delivery_boy/features/language/screens/choose_language_screen.dart';
import 'package:grocery_delivery_boy/features/order/providers/order_provider.dart';
import 'package:grocery_delivery_boy/features/profile/providers/profile_provider.dart';
import 'package:grocery_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:grocery_delivery_boy/helper/location_helper.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';


class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    return CustomPopScopeWidget(
      isExit: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          leadingWidth: 0,
          actions: [
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return (orderProvider.currentOrders?.isNotEmpty ?? false)
                    ? const SizedBox.shrink()
                    : IconButton(icon: Icon(Icons.refresh, color: Theme.of(context).textTheme.bodyLarge!.color),
                    onPressed: () {
                      orderProvider.refresh(context);
                    });
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'language':
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChooseLanguageScreen(fromHomeScreen: true)));
                }
              },
              icon: Icon(
                Icons.more_vert_outlined,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'language',
                  child: Row(
                    children: [
                      Icon(Icons.language, color: Theme.of(context).textTheme.bodyLarge!.color),
                      const SizedBox(width: Dimensions.paddingSizeLarge),
                      Text(
                        getTranslated('change_language', context),
                        style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
          leading: const SizedBox.shrink(),
          title: Consumer<ProfileProvider>(builder: (context, profileProvider, child) {
            return  profileProvider.userInfoModel != null ? Row(children: [
              Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FadeInImage.assetNetwork(
                    placeholder: Images.profilePlaceholder,
                    width: 40,
                    height: 40,
                    fit: BoxFit.fill,
                    imageErrorBuilder: (c, o, s) => Image.asset(Images.profilePlaceholder, height: 40, width: 40, fit: BoxFit.cover),

                    image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.deliveryManImageUrl}/${profileProvider.userInfoModel!.image}',
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Text('${profileProvider.userInfoModel?.fName ?? ''} ${profileProvider.userInfoModel?.lName ?? ''}',
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
            ) : const SizedBox.shrink();
          }),
        ),
        body: Consumer<OrderProvider>(builder: (context, orderProvider, child) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Consumer<PermissionHandlerProvider>(
              builder: (context, permissionProvider, child) {
                if(permissionProvider.isShownLocationWarning || permissionProvider.isShownNotificationWarning) {
                  return InkWell(
                    onTap: () async {
                      if(permissionProvider.isShownNotificationWarning){
                        permissionProvider.setOpenSetting(true);
                        await Geolocator.openAppSettings();
                      }else{
                        if(permissionProvider.locationPermission == LocationPermission.always || permissionProvider.locationPermission == LocationPermission.whileInUse) {
                          LocationHelper.onLocationShowDialog(context, dialog: LocationPermissionWidget(
                            fromDashboard: true,
                            onPressed: () async {
                              Navigator.pop(context);
                              permissionProvider.setOpenSetting(true);
                              await Geolocator.openAppSettings();
                            },
                          ));
                        }else {
                          if(context.mounted) {
                            await LocationHelper.checkPermission(context);
                            LocationPermission permission = await Geolocator.checkPermission();

                            permissionProvider.setLocationPermission(permission);


                          }
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      color: Colors.black,
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Flexible(child: Text(
                          getTranslated(permissionProvider.getWarningText(), context),
                          style: rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
                        )),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        Container(
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward, color: Colors.black),
                        ),

                      ]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Text(getTranslated('active_order', context), style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Expanded(child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                displacement: 0,
                color: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                onRefresh: () {
                  return orderProvider.refresh(context);
                },
                child: orderProvider.currentOrders == null ? Center(child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                )) : (orderProvider.currentOrders?.isNotEmpty ?? false) ? ListView.builder(
                  itemCount: orderProvider.currentOrders!.length,
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  itemBuilder: (context, index) => OrderWidget(
                    orderModel: orderProvider.currentOrders?[index],
                    index: index,
                  ),
                ) : Center(child: Text(getTranslated('no_order_found', context),style: rubikRegular)),
              ),
            )),
          ]);
        }),
      ),
    );
  }
}