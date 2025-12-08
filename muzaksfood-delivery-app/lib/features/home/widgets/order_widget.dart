import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/common/models/config_model.dart';
import 'package:grocery_delivery_boy/common/models/order_model.dart';
import 'package:grocery_delivery_boy/common/providers/tracker_provider.dart';
import 'package:grocery_delivery_boy/features/order/providers/order_provider.dart';
import 'package:grocery_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:grocery_delivery_boy/helper/location_helper.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/features/language/providers/localization_provider.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_button_widget.dart';
import 'package:grocery_delivery_boy/features/order/screens/order_details_screen.dart';
import 'package:provider/provider.dart';

class OrderWidget extends StatelessWidget {
  final OrderModel? orderModel;
  final int index;
  const OrderWidget({super.key, this.orderModel, required this.index});

  @override
  Widget build(BuildContext context) {

    final ConfigModel? configModel = Provider.of<SplashProvider>(context, listen: false).configModel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(
          color: Theme.of(context).shadowColor.withValues(alpha: .5),
          spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1),
        )],
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text(
                getTranslated('order_id', context),
                style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
              ),

              Text(
                ' # ${orderModel?.id}',
                style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
              ),
              
              // Express Badge
              if (orderModel?.isExpress == 1) ...[
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        getTranslated('express', context),
                        style: rubikMedium.copyWith(
                          fontSize: 10,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]),

            Stack(clipBehavior: Clip.none, children: [
              Container(),

              Provider.of<LocalizationProvider>(context).isLtr ? Positioned(
                right: -10,
                top: -23,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(Dimensions.paddingSizeSmall),
                          bottomLeft: Radius.circular(Dimensions.paddingSizeSmall))),
                  child: Text(
                    getTranslated('${orderModel?.orderStatus}', context),
                    style: rubikRegular
                        .copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall),
                  ),
                ),
              ) : Positioned(
                left: -10,
                top: -28,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(Dimensions.paddingSizeSmall),
                          bottomLeft: Radius.circular(Dimensions.paddingSizeSmall))),
                  child: Text(
                    getTranslated('${orderModel?.orderStatus}', context),
                    style: rubikRegular
                        .copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeSmall),
                  ),
                ),
              ),
            ]),

          ]),
          const SizedBox(height: 25),
          
          // Express ETA Countdown
          if (orderModel?.isExpress == 1 && orderModel?.expressEta != null) ...[
            _buildExpressEtaWidget(context),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],

          Row(children: [
            Image.asset(
              Images.location,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              width: Dimensions.paddingSizeDefault,
              height: Dimensions.paddingSizeLarge,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Text(
              orderModel?.deliveryAddress?.address ?? getTranslated('address_not_found', context),
              style: rubikRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color),
            )),
          ]),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(children: [
            if(orderModel?.deliveryAddress?.road != null) ...[
              Text('${getTranslated('road', context)} - ${orderModel?.deliveryAddress?.road}'),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ],

            if(orderModel?.deliveryAddress?.house != null) ...[
              Text('${getTranslated('house', context)} - ${orderModel?.deliveryAddress?.house}'),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),

            ],

            if(orderModel?.deliveryAddress?.floor != null) ...[
              Text('${getTranslated('floor', context)} - ${orderModel?.deliveryAddress?.floor}'),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),


            ],
          ]),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Row(children: [
            Expanded(
              child: CustomButtonWidget(
                btnTxt: getTranslated('view_details', context),
                onTap: () {
                  final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);

                  if(orderProvider.currentOrders?[index].orderStatus == 'out_for_delivery') {
                    LocationHelper.checkPermission(context, callBack: () {
                      Provider.of<TrackerProvider>(context, listen: false).startListenCurrentLocation();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderProvider.currentOrders![index].id)));
                    });
                  }else {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderModel?.id)));
                  }

                },
                isShowBorder: true,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeLarge),

            if(configModel?.googleMapStatus ?? false)...[
              Expanded(child: Consumer<TrackerProvider>(
                builder: (context, locationProvider, child) {
                  return CustomButtonWidget(
                    isLoading: locationProvider.isLoading && locationProvider.currentId == orderModel?.id,
                    btnTxt: getTranslated('direction', context),
                    onTap: () {
                      locationProvider.onChangeCurrentId(orderModel!.id!);

                      LocationHelper.checkPermission(context, callBack: () {
                        locationProvider.getUserCurrentLocation().then((position) {
                          LocationHelper.openMap(
                            destinationLatitude: double.parse(orderModel?.deliveryAddress?.latitude ?? '0'),
                            destinationLongitude: double.parse(orderModel?.deliveryAddress?.longitude ?? '0'),
                            userLatitude: position.latitude,
                            userLongitude: position.longitude,
                          );
                        });
                      });

                    },
                  );
                }
              )),
            ],
          ]),
        ],
      ),
    );
  }
  
  Widget _buildExpressEtaWidget(BuildContext context) {
    final DateTime? eta = orderModel?.expressEta != null 
        ? DateTime.tryParse(orderModel!.expressEta!) 
        : null;
    
    if (eta == null) return const SizedBox.shrink();
    
    final DateTime now = DateTime.now();
    final Duration remaining = eta.difference(now);
    final bool isOverdue = remaining.isNegative;
    final int minutesRemaining = remaining.inMinutes.abs();
    
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        border: Border.all(
          color: isOverdue ? Colors.red : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.timer,
            color: isOverdue ? Colors.red : Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue 
                      ? getTranslated('sla_breached', context)
                      : getTranslated('express_eta', context),
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: isOverdue ? Colors.red.shade900 : Colors.orange.shade900,
                  ),
                ),
                Text(
                  isOverdue
                      ? '${getTranslated('overdue_by', context)} $minutesRemaining ${getTranslated('min', context)}'
                      : '${getTranslated('deliver_in', context)} $minutesRemaining ${getTranslated('min', context)}',
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
