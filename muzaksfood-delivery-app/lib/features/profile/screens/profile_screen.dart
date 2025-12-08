import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_alert_dialog_widget.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_image_widget.dart';
import 'package:grocery_delivery_boy/helper/show_custom_snackbar_helper.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/features/auth/providers/auth_provider.dart';
import 'package:grocery_delivery_boy/features/profile/providers/profile_provider.dart';
import 'package:grocery_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/features/auth/screens/login_screen.dart';
import 'package:grocery_delivery_boy/features/html/screens/html_viewer_screen.dart';
import 'package:grocery_delivery_boy/common/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingCardModel {
  final IconData icon;
  final String title;
  final bool hasToggle;
  final bool? toggleValue;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const SettingCardModel({
    required this.icon,
    required this.title,
    required this.hasToggle,
    this.toggleValue,
    this.onToggle,
    this.onTap,
  });
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: Consumer2<ProfileProvider, ThemeProvider>(
        builder: (context, profileProvider, themeProvider, child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section with dark green background
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top * 0.6,
                left: Dimensions.paddingSizeLarge,
                right: Dimensions.paddingSizeLarge,
                bottom: Dimensions.paddingSizeExtraLarge,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge * 2),
                        child: CustomImageWidget(
                          placeholder: Images.placeholderUser,
                          width: Dimensions.radiusExtraLarge * 4,
                          height: Dimensions.radiusExtraLarge * 4,
                          fit: BoxFit.cover,
                          image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls?.deliveryManImageUrl}/${profileProvider.userInfoModel?.image ?? ''}',
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.paddingSizeLarge),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileProvider.userInfoModel?.fName != null
                                ? '${profileProvider.userInfoModel?.fName ?? ''} ${profileProvider.userInfoModel?.lName ?? ''}'
                                : "",
                            style: rubikMedium.copyWith(
                              fontSize: Dimensions.fontSizeOverLarge,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text(
                            profileProvider.userInfoModel?.phone ?? "",
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),


            // Settings Cards Section
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(
                  left: Dimensions.paddingSizeLarge,
                  right: Dimensions.paddingSizeLarge,
                  bottom: Dimensions.paddingSizeLarge,
                ),
                child: ListView.separated(
                  itemCount: _getSettingsItems(context, themeProvider).length,
                  itemBuilder: (context, index) {
                    final item = _getSettingsItems(context, themeProvider)[index];
                    return SettingsCard(
                      icon: item.icon,
                      title: item.title,
                      hasToggle: item.hasToggle,
                      toggleValue: item.toggleValue,
                      onToggle: item.onToggle,
                      onTap: item.onTap,
                    );
                  },
                  separatorBuilder: (ctx, i) => SizedBox(height: Dimensions.paddingSizeDefault),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SettingCardModel> _getSettingsItems(BuildContext context, ThemeProvider themeProvider) {
    return [
      // Dark Mode Card
      SettingCardModel(
        icon: Icons.dark_mode,
        title: getTranslated('dark_mode', context),
        hasToggle: true,
        toggleValue: themeProvider.darkTheme,
        onToggle: () => themeProvider.toggleTheme(),
        onTap: null,
      ),


      // Privacy Policy Card
      SettingCardModel(
        icon: Icons.privacy_tip,
        title: getTranslated('privacy_policy', context),
        hasToggle: false,
        toggleValue: null,
        onToggle: null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HtmlViewerScreen(isPrivacyPolicy: true),
            ),
          );
        },
      ),

      // Terms & Condition Card
      SettingCardModel(
        icon: Icons.description,
        title: getTranslated('terms_and_condition', context),
        hasToggle: false,
        toggleValue: null,
        onToggle: null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HtmlViewerScreen(isPrivacyPolicy: false),
            ),
          );
        },
      ),

      // Delete Account
      SettingCardModel(
        icon: CupertinoIcons.delete,
        title: getTranslated('delete_account', context),
        hasToggle: false,
        toggleValue: null,
        onToggle: null,
        onTap: () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (ctx) => Consumer<AuthProvider>(builder: (context, authProvider, child)=> CustomAlertDialogWidget(
              iconWidget: Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle
                  ),
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Icon(CupertinoIcons.delete, color: Theme.of(context).cardColor, size: 40)
              ),
              title: getTranslated('delete_your_account', context),
              subTitle: getTranslated('all_your_personal_data_will_be_removed', context),
              leftButtonText: getTranslated('delete', context),
              rightButtonText: getTranslated('cancel', context),
              rightButtonColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              leftButtonColor: Theme.of(context).primaryColor,
              leftButtonTextStyle: rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
              rightButtonTextStyle: rubikMedium.copyWith(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: Dimensions.fontSizeLarge),
              leftLoading: authProvider.isLoading,
              onPressLeft: () {
                authProvider.permanentDelete().then((response){
                  if(response.isSuccess){
                    authProvider.clearSharedData();
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false,);
                    showCustomSnackBarHelper(getTranslated('your_account_has_been_deleted', context), isError: false);
                  }else{
                    Navigator.pop(context);
                    showCustomSnackBarHelper(getTranslated('you_couldnot_delete_your_account_while_delivers_are_in_preogress', context));
                  }
                });

              },
              onPressRight: () => Navigator.pop(context),
            )),
          );
        },
      ),

      // Logout Card
      SettingCardModel(
        icon: Icons.logout,
        title: getTranslated('logOut', context),
        hasToggle: false,
        toggleValue: null,
        onToggle: null,
        onTap: () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (ctx) => CustomAlertDialogWidget(
              title: getTranslated('log_out', context),
              subTitle: getTranslated('are_you_sure_you_want_to_logout', context),
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
                Provider.of<AuthProvider>(context, listen: false).clearSharedData();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                  showCustomSnackBarHelper(getTranslated('logout_successful', context), isError: false); // Close the app
              },
              rightButtonColor: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              leftButtonColor: Theme.of(context).primaryColor,
              rightButtonTextStyle: rubikMedium.copyWith(color: Theme.of(context).textTheme.titleMedium?.color, fontSize: Dimensions.fontSizeLarge),
              leftButtonTextStyle: rubikMedium.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeLarge),
            ),
          );
        },
      ),
    ];
  }
}

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool hasToggle;
  final bool? toggleValue;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.hasToggle,
    this.toggleValue,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: Dimensions.paddingSizeSmall,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).hintColor,
                  size: Dimensions.fontSizeOverLarge,
                ),
                SizedBox(width: Dimensions.paddingSizeLarge),
                Expanded(
                  child: Text(
                    title,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                if (hasToggle)
                  Switch(
                    value: toggleValue ?? false,
                    onChanged: (value) => onToggle?.call(),
                    activeThumbColor: Theme.of(context).primaryColor,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


