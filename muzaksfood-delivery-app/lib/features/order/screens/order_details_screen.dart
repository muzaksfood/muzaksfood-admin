import 'dart:math';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/common/models/config_model.dart';
import 'package:grocery_delivery_boy/common/models/order_model.dart';
import 'package:grocery_delivery_boy/features/dashboard/screens/dashboard_screen.dart';
import 'package:grocery_delivery_boy/features/order/domain/models/timeslot_model.dart';
import 'package:grocery_delivery_boy/features/order/widgets/order_image_note_widget.dart';
import 'package:grocery_delivery_boy/features/order/widgets/slider_button_widget.dart';
import 'package:grocery_delivery_boy/helper/date_converter_helper.dart';
import 'package:grocery_delivery_boy/helper/location_helper.dart';
import 'package:grocery_delivery_boy/helper/price_converter_helper.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/features/auth/providers/auth_provider.dart';
import 'package:grocery_delivery_boy/features/language/providers/localization_provider.dart';
import 'package:grocery_delivery_boy/features/order/providers/order_provider.dart';
import 'package:grocery_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:grocery_delivery_boy/common/providers/tracker_provider.dart';
import 'package:grocery_delivery_boy/main.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_button_widget.dart';
import 'package:grocery_delivery_boy/helper/show_custom_snackbar_helper.dart';
import 'package:grocery_delivery_boy/features/chat/screens/chat_screen.dart';
import 'package:grocery_delivery_boy/features/order/screens/order_delivered_screen.dart';
import 'package:grocery_delivery_boy/features/order/widgets/custom_divider_widget.dart';
import 'package:grocery_delivery_boy/features/order/widgets/delivery_dialog_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int? orderId;
  const OrderDetailsScreen({super.key, this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {

  void _loadData() {
    if(widget.orderId != null) {
      Provider.of<OrderProvider>(context, listen: false).getOrderModel('${widget.orderId}');
      Provider.of<OrderProvider>(Get.context!, listen: false).getOrderDetails(widget.orderId.toString());

    }
  }

  // void _updateOrderStatus(String status) async {
  //   String token = Provider.of<AuthProvider>(context, listen: false).getUserToken();
  //   OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);
  //
  //   ResponseModel response = await orderProvider.updateOrderStatus(
  //     token: token,
  //     orderId: orderProvider.currentOrderModel?.id,
  //     status: status,
  //   );
  //
  //   if (response.isSuccess) {
  //     setState(() {
  //       orderProvider.currentOrderModel?.orderStatus = status;
  //     });
  //     // Refresh order details to get updated data
  //     orderProvider.getOrderDetails(orderProvider.currentOrderModel!.id.toString());
  //   }
  // }

  @override
  void initState() {

    _loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final ConfigModel? configModel = Provider.of<SplashProvider>(context, listen: false).configModel;
    final String token = Provider.of<AuthProvider>(context, listen: false).getUserToken();


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if(didPop) return;

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          return;
        } else if(!didPop && !Navigator.canPop(context)){
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> DashboardScreen()));
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            onPressed: (){
              if(!Navigator.canPop(context)){
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=> DashboardScreen()));
              } else{
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            getTranslated('order_details', context),
            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).textTheme.bodyLarge!.color),
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            double itemsPrice = 0;
            double discount = 0;
            double extraDiscount = orderProvider.currentOrderModel?.extraDiscount ?? 0;
            double tax = 0;
            bool? isVatInclude = false;
            TimeSlotModel? timeSlot;
            double deliveryCharge = _getDeliveryCharge(orderProvider.currentOrderModel) ?? 0;

            if (orderProvider.orderDetails != null && orderProvider.currentOrderModel?.orderAmount != null) {
              for (var orderDetails in orderProvider.orderDetails!) {
                itemsPrice = itemsPrice + (orderDetails.price! * orderDetails.quantity!);
                discount = discount + (orderDetails.discountOnProduct! * orderDetails.quantity!);
                tax = tax + (orderDetails.taxAmount! * orderDetails.quantity!);
                isVatInclude = orderDetails.isVatInclude;
              }
              try{
                timeSlot = orderProvider.timeSlots!.firstWhere((timeSlot) => timeSlot.id == orderProvider.currentOrderModel?.timeSlotId);
              }catch(e) {
                timeSlot = null;
              }
            }
            double subTotal = itemsPrice + (isVatInclude! ? 0 : tax);


            double totalPrice = subTotal - discount + deliveryCharge - (orderProvider.currentOrderModel?.couponDiscountAmount ?? 0) - extraDiscount;

            List<OrderPartialPayment> paymentList = [];
            double dueAmount = 0;

            if(orderProvider.currentOrderModel != null &&  orderProvider.currentOrderModel?.orderPartialPayments != null && orderProvider.currentOrderModel!.orderPartialPayments!.isNotEmpty){

              paymentList.addAll(orderProvider.currentOrderModel!.orderPartialPayments!);

              if((orderProvider.currentOrderModel?.orderPartialPayments?.first.dueAmount ?? 0) > 0 ){
                dueAmount = orderProvider.currentOrderModel?.orderPartialPayments?.first.dueAmount ?? 0;
                paymentList.add(OrderPartialPayment(
                  id: -1, paidAmount: 0,
                  paidWith: orderProvider.currentOrderModel?.paymentMethod,
                  dueAmount: orderProvider.currentOrderModel?.orderPartialPayments?.first.dueAmount,
                ));
              }
            }


            return orderProvider.orderDetails != null && orderProvider.currentOrderModel != null || orderProvider.isLoading? Column(children: [


              if(orderProvider.currentOrderModel !=null && orderProvider.currentOrderModel!.bringChangeAmount != null && orderProvider.currentOrderModel!.bringChangeAmount! > 0)Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                        Dimensions.radiusDefault
                    ),
                    color: Colors.blue.withValues(alpha: 0.1)
                ),
                margin: EdgeInsets.fromLTRB(10,15, 10,5),
                padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                child: Row(
                  spacing: Dimensions.paddingSizeExtraSmall, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.info, color: Colors.blue, size: 18,),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              height: 1.5
                          ),
                          children: <TextSpan>[
                            TextSpan(text: getTranslated("please_bring", context),  style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                            )),
                            TextSpan(text: " ${PriceConverterHelper.convertPrice(context, orderProvider.currentOrderModel?.bringChangeAmount ?? 0)} ", style: rubikSemiBold),
                            TextSpan(text: getTranslated('in_change_for_the_customer_when_making_the_delivery', context),  style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),

                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              Expanded(
                child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    children: [
                      Row(children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(child: Text(getTranslated('order_id', context), style: rubikRegular.copyWith())),

                              Text(' # ${orderProvider.currentOrderModel?.id}', style: rubikMedium),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.watch_later, size: 17),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                             if(orderProvider.currentOrderModel?.createdAt != null) Text(DateConverterHelper.isoStringToLocalDateOnly(orderProvider.currentOrderModel!.createdAt!),
                                  style: rubikRegular.copyWith()),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),

                      timeSlot != null ? Row(children: [
                        Text('${getTranslated('delivery_time', context)}:', style: rubikRegular),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(DateConverterHelper.convertTimeRange(timeSlot.startTime!, timeSlot.endTime!, context), style: rubikMedium),
                      ]) : const SizedBox(),
                      const SizedBox(height: Dimensions.paddingSizeLarge),


                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(
                            color: Theme.of(context).shadowColor,
                            blurRadius: 5, spreadRadius: 1,
                          )],
                        ),
                        child:  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(getTranslated('customer', context), style: rubikRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall
                          )),
                          ListTile(
                            leading: ClipOval(
                              child: FadeInImage.assetNetwork(
                                placeholder: Images.placeholderUser,
                                image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.customerImageUrl}/${orderProvider.currentOrderModel?.customer?.image ?? ''}',
                                height: 40, width: 40, fit: BoxFit.cover,
                                imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholderUser, height: 40, width: 40, fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(
                              orderProvider.currentOrderModel?.deliveryAddress?.contactPersonName ?? '',
                              style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                            ),
                            trailing: orderProvider.currentOrderModel?.deliveryAddress?.contactPersonNumber != null ? InkWell(
                              onTap: () {
                                launchUrlString('tel:${orderProvider.currentOrderModel?.deliveryAddress?.contactPersonNumber}', mode: LaunchMode.externalApplication);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
                                child: const Icon(Icons.call_outlined),
                              ),
                            ) : const SizedBox(),
                          ),
                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Text('${getTranslated('item', context)}:', style: rubikRegular.copyWith()),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text(orderProvider.orderDetails!.length.toString(), style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                          ]),
                          orderProvider.currentOrderModel?.orderStatus == 'processing' || orderProvider.currentOrderModel?.orderStatus == 'out_for_delivery'
                              ? Row(children: [
                            Text('${getTranslated('payment_status', context)}:',
                                style: rubikRegular.copyWith()),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text(getTranslated('${orderProvider.currentOrderModel?.paymentStatus}', context),
                                style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                          ])
                              : const SizedBox.shrink(),
                        ],
                      ),
                      const Divider(height: Dimensions.paddingSizeLarge),


                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orderProvider.orderDetails!.length,
                        itemBuilder: (context, index) {
                          final String variationValue = _getVariationValue(orderProvider.orderDetails?[index].modifiedVariation).replaceAll(' ', '');

                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: FadeInImage.assetNetwork(
                                  placeholder: Images.placeholderImage, height: 70, width: 80, fit: BoxFit.cover,
                                  image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.productImageUrl}/${
                                      (orderProvider.orderDetails?[index].productDetails?.image?.isNotEmpty ?? false) ? (orderProvider.orderDetails?[index].productDetails?.image?.first) : ''
                                  }',
                                  imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholderImage, height: 70, width: 80, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeSmall),

                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          orderProvider.orderDetails![index].productDetails!.name!,
                                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text('${getTranslated('quantity', context)}:', style: rubikRegular),
                                      const SizedBox(
                                        width: 5.0,
                                      ),
                                      Text(orderProvider.orderDetails![index].quantity.toString(), style: rubikRegular.copyWith(color: Theme.of(context).primaryColor)),
                                    ],
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                                  Row(children: [
                                    Text(
                                      PriceConverterHelper.convertPrice(context, orderProvider.orderDetails![index].price! - orderProvider.orderDetails![index].discountOnProduct!.toDouble()),
                                      style: rubikRegular,
                                    ),
                                    const SizedBox(width: 5),

                                    orderProvider.orderDetails![index].discountOnProduct! > 0 ? Expanded(child: Text(
                                      PriceConverterHelper.convertPrice(context, orderProvider.orderDetails![index].price!.toDouble()),
                                      style: rubikRegular.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    )) : const SizedBox(),
                                  ]),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                 Builder(
                                   builder: (context) {

                                     return (variationValue.isNotEmpty && variationValue != 'null') ? Row(children: [

                                         Container(height: 10, width: 10, decoration: BoxDecoration(
                                           shape: BoxShape.circle,
                                           color: Theme.of(context).textTheme.bodyLarge!.color,
                                         )),
                                       const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                       Text(variationValue,
                                         style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                       ),
                                     ]) : const SizedBox();
                                   }
                                 )



                                ]),
                              ),

                            ]),

                            const Divider(height: Dimensions.paddingSizeLarge),
                          ]);
                        },
                      ),


                      (orderProvider.currentOrderModel?.orderNote != null && orderProvider.currentOrderModel!.orderNote!.isNotEmpty) ? Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(width: 1, color: Theme.of(context).hintColor),
                        ),
                        child: Text('${orderProvider.currentOrderModel?.orderNote}', style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                      ) : const SizedBox(),

                      if(orderProvider.currentOrderModel?.orderImageList?.isNotEmpty ?? false) OrderImageNoteWidget(orderModel: orderProvider.currentOrderModel),

                      // Total
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('items_price', context), style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        Text(PriceConverterHelper.convertPrice(context, itemsPrice), style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge)),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${getTranslated('tax', context)} ${isVatInclude? getTranslated('include', context) : '' }',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                        Text('${isVatInclude? '' : '(+)'} ${PriceConverterHelper.convertPrice(context, tax)}',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                        child: CustomDividerWidget(),
                      ),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('subtotal', context),
                            style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                        Text(PriceConverterHelper.convertPrice(context, subTotal),
                            style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('discount', context),
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                        Text('(-) ${PriceConverterHelper.convertPrice(context, discount)}',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      if(extraDiscount > 0) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('extra_discount', context),
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                        Text('(-) ${PriceConverterHelper.convertPrice(context, extraDiscount)}',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      ]),
                      if(extraDiscount > 0) const SizedBox(height: 10),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('coupon_discount', context),
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                        Text(
                          '(-) ${PriceConverterHelper.convertPrice(context, orderProvider.currentOrderModel?.couponDiscountAmount ?? 0)}',
                          style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, ),
                        ),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('delivery_fee', context),
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                        Text('(+) ${PriceConverterHelper.convertPrice(context, deliveryCharge)}',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge, )),
                      ]),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                        child: CustomDividerWidget(),
                      ),

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(getTranslated('total_amount', context),
                            style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor)),
                        Text(
                          PriceConverterHelper.convertPrice(context, totalPrice),
                          style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).primaryColor),
                        ),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      if(orderProvider.currentOrderModel?.orderPartialPayments != null && orderProvider.currentOrderModel!.orderPartialPayments!.isNotEmpty)...[
                        DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            dashPattern: const [8, 4],
                            strokeWidth: 1.1,
                            color: Theme.of(context).colorScheme.primary,
                            radius: const Radius.circular(Dimensions.radiusDefault),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.02),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeSmall, vertical: 1),
                            child: Column(children: paymentList.map((payment) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                                Text("${getTranslated(payment.paidAmount! > 0 ? 'paid_amount' : 'due_amount', context)} (${getTranslated('${payment.paidWith}', context)})",
                                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color),
                                  overflow: TextOverflow.ellipsis,),

                                Text( PriceConverterHelper.convertPrice(context, payment.paidAmount! > 0 ? payment.paidAmount : payment.dueAmount),
                                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color),),
                              ]),
                            )).toList()),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],


                    ],
                  ),
              ),
              if((orderProvider.currentOrderModel?.orderStatus == 'processing' || orderProvider.currentOrderModel?.orderStatus == 'out_for_delivery') && (configModel?.googleMapStatus ?? false))...[
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Consumer<TrackerProvider>(
                    builder: (context, locationProvider, _) {
                      return CustomButtonWidget(
                          isLoading: locationProvider.isLoading && orderProvider.currentOrderModel?.id == locationProvider.currentId,
                          btnTxt: getTranslated('direction', context),
                          onTap: () {
                            locationProvider.onChangeCurrentId(orderProvider.currentOrderModel!.id!);

                            LocationHelper.checkPermission(context, callBack: () {

                              Provider.of<TrackerProvider>(context, listen: false).getUserCurrentLocation().then((position) {

                                LocationHelper.openMap(
                                  destinationLatitude: double.parse(orderProvider.currentOrderModel?.deliveryAddress?.latitude ?? '0'),
                                  destinationLongitude: double.parse(orderProvider.currentOrderModel?.deliveryAddress?.longitude ?? '0'),
                                  userLatitude: position.latitude,
                                  userLongitude: position.longitude,
                                );
                              });
                            });

                          });
                    },
                  ),
                ),
              ],

                orderProvider.currentOrderModel?.orderStatus != 'delivered' && !(orderProvider.currentOrderModel?.isGuestOrder ?? false) ? Center(
                  child: Container(
                    width: 1170,
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: CustomButtonWidget(btnTxt: getTranslated('chat_with_customer', context), onTap: (){
                      if(orderProvider.currentOrderModel?.customer != null) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(orderModel: orderProvider.currentOrderModel)));
                      }else{
                        showCustomSnackBarHelper(getTranslated('user_not_available', context));
                      }

                    }),
                  ),
                ) : const SizedBox(),

                orderProvider.currentOrderModel?.orderStatus == 'processing' ? Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .05)),
                  ),
                  child: Transform.rotate(
                    angle: Provider.of<LocalizationProvider>(context).isLtr ? pi * 2 : pi, // in radians
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: SliderButtonWidget(
                        // isLoading: orderProvider.isLoading,
                        action: () {
                          LocationHelper.checkPermission(context, callBack: () async {

                            Provider.of<TrackerProvider>(context, listen: false).startListenCurrentLocation();

                             await orderProvider.updateOrderStatus(
                                token: token,
                                orderId: orderProvider.currentOrderModel?.id,
                                status: 'out_for_delivery',
                              );
                             await orderProvider.getOrderModel(widget.orderId.toString());

                              orderProvider.getAllOrders();

                          });
                        },

                        ///Put label over here
                        label: Text(
                          getTranslated('swip_to_deliver_order', context),
                          style: rubikRegular.copyWith(color: Theme.of(context).primaryColor),
                        ),
                        dismissThresholds: 0.5,
                        dismissible: false,
                        shimmer: false,
                        width: MediaQuery.of(context).size.width - Dimensions.paddingSizeDefault,
                        icon: const Center(
                            child: Icon(
                              Icons.double_arrow_sharp,
                              color: Colors.white,
                              size: Dimensions.paddingSizeLarge,
                              semanticLabel: 'Text to announce in accessibility modes',
                            )),

                        ///Change All the color and size from here.
                        radius: 10,
                        boxShadow: const BoxShadow(blurRadius: 0.0),
                        buttonColor: Theme.of(context).primaryColor,
                        backgroundColor: Theme.of(context).cardColor,
                        baseColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                )
                    : orderProvider.currentOrderModel?.orderStatus == 'out_for_delivery'
                    ? Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .05)),
                  ),
                  child: Transform.rotate(
                    angle: Provider.of<LocalizationProvider>(context).isLtr ? pi * 2 : pi, // in radians
                    child: Directionality(
                      textDirection: TextDirection.ltr, // set it to rtl
                      child: SliderButtonWidget(
                        action: () async {
                          if (orderProvider.currentOrderModel?.paymentStatus == 'paid') {
                            Provider.of<OrderProvider>(Get.context!, listen: false).getOrdersCount().then((orderCount){
                              if(orderCount !=null && orderCount.outForDelivery !=null && orderCount.outForDelivery! < 1){
                                Provider.of<TrackerProvider>(Get.context!, listen: false).stopListening();
                              }
                            });

                           await orderProvider.updateOrderStatus(
                              token: token, orderId: widget.orderId,
                              status: 'delivered',
                            );

                            Navigator.pushReplacement(context, MaterialPageRoute(
                              builder: (_) => OrderDeliveredScreen(orderID: orderProvider.currentOrderModel?.id.toString()),
                            ));


                          } else {
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                    child: DeliveryDialogWidget(
                                      onTap: () {},
                                      totalPrice: ( dueAmount > 0 ? dueAmount : totalPrice),
                                      orderModel: orderProvider.currentOrderModel,
                                    ),
                                  );
                                });
                          }
                        },

                        ///Put label over here
                        label: Text(
                          getTranslated('swip_to_confirm_order', context),
                          style: rubikRegular.copyWith(color: Theme.of(context).primaryColor),
                        ),
                        dismissThresholds: 0.5,
                        dismissible: false,
                        shimmer: false,
                        width: MediaQuery.of(context).size.width - Dimensions.paddingSizeDefault,
                        icon: const Center(
                            child: Icon(
                              Icons.double_arrow_sharp,
                              color: Colors.white,
                              size: Dimensions.paddingSizeLarge,
                              semanticLabel: 'Text to announce in accessibility modes',
                            )),

                        ///Change All the color and size from here.
                        radius: 10,
                        boxShadow: const BoxShadow(blurRadius: 0.0),
                        buttonColor: Theme.of(context).primaryColor,
                        backgroundColor: Theme.of(context).cardColor,
                        baseColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ],
            )
                : Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)));
          },
        ),
      ),
    );
  }


  String _getVariationValue(Map<String, dynamic>? orderVariation) {
    String variation = '';

    orderVariation?.forEach((key, value) {
      variation = '$variation ${variation.isEmpty ? '' : '-'} $value';
    });

    return variation;
  }

  double? _getDeliveryCharge(OrderModel? order) {
    if(order?.orderType == 'delivery') {
      return (order?.deliveryCharge ?? 0.0) + (order?.weightCharge ?? 0.0);
    }
    return null;
  
  }
}
