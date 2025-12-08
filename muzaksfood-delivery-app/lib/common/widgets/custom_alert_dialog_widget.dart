import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';

import 'custom_button_widget.dart';


class CustomAlertDialogWidget extends StatelessWidget {
  final String? image;
  final IconData? icon;
  final String? title;
  final String? subTitle;
  final String? leftButtonText;
  final String? rightButtonText;
  final Function? onPressLeft;
  final Function? onPressRight;
  final Color? iconColor;
  final Widget? child;
  final Widget? iconWidget;
  final bool? rightLoading;
  final bool? leftLoading;
  final Color? rightButtonColor;
  final Color? leftButtonColor;
  final TextStyle? leftButtonTextStyle;
  final TextStyle? rightButtonTextStyle;

  const CustomAlertDialogWidget({
    super.key, this.image, this.icon,
    this.title, this.subTitle, this.leftButtonText,
    this.rightButtonText, this.onPressLeft,  this.onPressRight, this.leftButtonColor,
    this.iconColor, this.child, this.rightLoading = false, this.rightButtonColor,
    this.iconWidget, this.leftButtonTextStyle, this.rightButtonTextStyle,
    this.leftLoading = false
  });

  @override
  Widget build(BuildContext context) {
    return _CustomAlertDialogShape(
      child: child ?? Container(
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeLarge,
          horizontal: Dimensions.paddingSizeLarge,
        ),
        width: MediaQuery.sizeOf(context).width,
        child: Column(mainAxisSize: MainAxisSize.min, children: [


          if(image != null) Image.asset(image!, width: 50),

          if(icon != null) Icon(icon!, size: 50, color: iconColor ?? Theme.of(context).colorScheme.error),

          if(iconWidget != null) iconWidget!,

          const SizedBox(height: Dimensions.paddingSizeDefault),

         if(title != null) Text(title!, style: rubikBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
          ), textAlign: TextAlign.center),
          const SizedBox(height: Dimensions.paddingSizeDefault),


          if(subTitle != null) Text(subTitle!, style: rubikRegular.copyWith(
            fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor.withValues(alpha: 0.7)
          ), textAlign: TextAlign.center),

          const SizedBox(height: 50),


          Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: SizedBox(
              width: null,
              child: CustomButtonWidget(
                isLoading: leftLoading ?? false,
                backgroundColor: leftButtonColor ?? Theme.of(context).disabledColor.withValues(alpha: 0.2),
                btnTxt: leftButtonText ?? getTranslated('no', context),
                style: leftButtonTextStyle ?? rubikMedium.copyWith(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: Dimensions.fontSizeLarge),
                onTap: onPressLeft ?? ()=> Navigator.pop(context),
              ),
            )),
            const SizedBox(width: Dimensions.paddingSizeDefault),


            Flexible(child: SizedBox(
              width: null,
              child: CustomButtonWidget(
                backgroundColor: rightButtonColor,
                isLoading: rightLoading ?? false,
                btnTxt:  rightButtonText ?? getTranslated('yes', context),
                style: rightButtonTextStyle,
                onTap: onPressRight ?? ()=> Navigator.pop(context),
              ),
            )),

          ]),



        ]),
      ),
    );
  }
}


class _CustomAlertDialogShape extends StatelessWidget {
  final Widget child;
  // ignore: unused_element_parameter
  const _CustomAlertDialogShape({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius:  const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const SizedBox(width: 25),

          Container(height: 5, width: 40, decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(25),
          )),

          InkWell(
            onTap: ()=> Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).hintColor.withValues(alpha: 0.1)
              ),
              padding: EdgeInsets.all(7),
              child: Image.asset(Images.crossIcon, height: Dimensions.paddingSizeSmall, width: Dimensions.paddingSizeSmall),
            ),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        child,

      ]),
    );
  }
}
