import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_alert_dialog_widget.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';



class CustomPopScopeWidget extends StatefulWidget {
  final Widget child;
  final Function()? onPopInvoked;
  final bool isExit;

  const CustomPopScopeWidget({super.key, required this.child, this.onPopInvoked, this.isExit = true});

  @override
  State<CustomPopScopeWidget> createState() => _CustomPopScopeWidgetState();
}

class _CustomPopScopeWidgetState extends State<CustomPopScopeWidget> {

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {

        if (widget.onPopInvoked != null) {
          widget.onPopInvoked!();
        }

        if(didPop) {
          return;
        }

        if(!Navigator.canPop(context) && widget.isExit ) {

          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Adjusts the height to fit the content
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)), // Optional: Round the top corners
            ),
            builder: (context) => CustomAlertDialogWidget(
              title: getTranslated('exit_app', context),
              subTitle: getTranslated('are_you_sure_you_want_to_exit', context),
              rightButtonText: getTranslated('cancel', context),
              leftButtonText: getTranslated('yes', context),
              iconWidget: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).hintColor.withValues(alpha: 0.1)
                ),
                padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Image.asset(Images.exitIcon, height: 30, width: 30),
              ),
              onPressLeft: () {
                Navigator.of(context).pop(); // Close the bottom sheet
                SystemNavigator.pop(); // Close the app
              },
              rightButtonColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              leftButtonColor: Theme.of(context).primaryColor,
              rightButtonTextStyle: rubikMedium.copyWith(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: Dimensions.fontSizeLarge),
              leftButtonTextStyle: rubikMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeLarge),
            ),
          );
        }else {
          if(Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }

      },
      child: widget.child,
    );
  }
}
