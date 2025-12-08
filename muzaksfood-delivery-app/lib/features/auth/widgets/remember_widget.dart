import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/features/auth/providers/auth_provider.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:provider/provider.dart';

class RememberWidget extends StatelessWidget {
  const RememberWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          InkWell(
            onTap: ()=> authProvider.onChangeRememberStatus(),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: authProvider.isActiveRememberMe ? Theme.of(context).primaryColor : Theme.of(context).highlightColor,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: authProvider.isActiveRememberMe
                    ? Icon(Icons.done, color: Theme.of(context).primaryColor, size: 17)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Text(getTranslated('remember_me', context), style: rubikRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
              ))
            ],
            ),
          ),
        ]);
      }
    );
  }
}
