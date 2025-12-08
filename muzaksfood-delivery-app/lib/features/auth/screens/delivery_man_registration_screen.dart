import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_boy/common/models/config_model.dart';
import 'package:grocery_delivery_boy/features/auth/domain/models/delivery_man_body_model.dart';
import 'package:grocery_delivery_boy/helper/email_checker_helper.dart';
import 'package:grocery_delivery_boy/localization/language_constrants.dart';
import 'package:grocery_delivery_boy/main.dart';
import 'package:grocery_delivery_boy/features/auth/providers/auth_provider.dart';
import 'package:grocery_delivery_boy/features/splash/providers/splash_provider.dart';
import 'package:grocery_delivery_boy/utill/dimensions.dart';
import 'package:grocery_delivery_boy/utill/images.dart';
import 'package:grocery_delivery_boy/utill/styles.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_app_bar_widget.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_button_widget.dart';
import 'package:grocery_delivery_boy/helper/show_custom_snackbar_helper.dart';
import 'package:grocery_delivery_boy/common/widgets/custom_text_field_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:provider/provider.dart';

class DeliveryManRegistrationScreen extends StatefulWidget {
  const DeliveryManRegistrationScreen({super.key});

  @override
  State<DeliveryManRegistrationScreen> createState() => _DeliveryManRegistrationScreenState();
}

class _DeliveryManRegistrationScreenState extends State<DeliveryManRegistrationScreen> {
  final TextEditingController _fNameController = TextEditingController();
  final TextEditingController _lNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _identityNumberController = TextEditingController();

  final FocusNode _fNameNode = FocusNode();
  final FocusNode _lNameNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _phoneNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();
  final FocusNode _identityNumberNode = FocusNode();
  String? _countryDialCode;

  @override
  void initState() {
    super.initState();
    
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

    _countryDialCode = CountryCode.fromCountryCode(splashProvider.configModel!.country!).dialCode;
    authProvider.onPickDmImage(false, true);
    authProvider.setIdentityTypeIndex(authProvider.identityTypeList[0], false);

    authProvider.loadBranchList();
    authProvider.setBranchIndex(0, isUpdate: false);

  }



  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: CustomAppBarWidget(title: getTranslated('delivery_man_registration', context)),
      body: Consumer<AuthProvider>(builder: (context,  authProvider, _) {
        List<int> branchIndexList = _getBranchIndexList(authProvider.branchList ?? []);

        return Column(children: [
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Expanded(child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), spreadRadius: 2, blurRadius: 12, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    getTranslated('basic_information', context),
                    style: rubikBold,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Container(
                    width: size.width,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                    ),
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        getTranslated('profile_image', context),
                        style: rubikBold,
                      ),

                      Text(
                        '${getTranslated('upload_jpg_png_and_less_than', context)} 150 ${getTranslated('mb', context)}',
                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Center(child: DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            dashPattern: const [8, 4],
                            strokeWidth: 1.1,
                            color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                            radius: const Radius.circular(Dimensions.radiusDefault),
                          ),
                          child: Stack(children: [
                            authProvider.pickedImage != null ?
                            ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                child: Image.file(File(authProvider.pickedImage!.path), width: 100, height: 100, fit: BoxFit.cover)
                            ) :
                            InkWell(
                              onTap: ()=> authProvider.onPickDmImage(true, false),
                              child: Container(
                                height: 100, width: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Image.asset(Images.galleryIcon, height: 24, width: 24),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),

                                  Text(getTranslated('click_to_add', context), style: rubikMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      color: Theme.of(context).hintColor.withValues(alpha: 0.6)
                                  ))
                                ]),
                              ),
                            ),

                            if(authProvider.pickedImage != null)
                              Positioned(bottom: 0, right: 0, top: 0, left: 0, child: InkWell(
                              onTap: () => authProvider.onPickDmImage(true, false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white),
                              ),
                            )),
                          ])
                      ))
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  CustomTextFieldWidget(
                    hintText: getTranslated('first_name', context),
                    controller: _fNameController,
                    capitalization: TextCapitalization.words,
                    inputType: TextInputType.name,
                    focusNode: _fNameNode,
                    nextFocus: _lNameNode,
                    showTitle: true,
                    isShowBorder: true,
                    isRequired: true,
                    prefixIconUrl: Images.profileIcon,
                    isShowPrefixIcon: true,
                    borderRadius: Dimensions.radiusDefault,
                    onTap: (){setState(() {});},
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  CustomTextFieldWidget(
                    hintText: getTranslated('last_name', context),
                    controller: _lNameController,
                    capitalization: TextCapitalization.words,
                    inputType: TextInputType.name,
                    focusNode: _lNameNode,
                    nextFocus: _emailNode,
                    showTitle: true,
                    isShowBorder: true,
                    isRequired: true,
                    prefixIconUrl: Images.profileIcon,
                    isShowPrefixIcon: true,
                    borderRadius: Dimensions.radiusDefault,
                    onTap: (){setState(() {});},
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5))
                    ),
                    child: Row(children: [
                      Container(
                        height: 60, width: size.width * 0.18,
                        decoration: BoxDecoration(
                          color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(Dimensions.paddingSizeSmall),
                              bottomLeft: Radius.circular(Dimensions.paddingSizeSmall),
                            )
                        ),
                        child: CountryCodePicker(
                          flagWidth: 20,
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          onChanged: (CountryCode countryCode) {
                            setState(() {
                              _countryDialCode = countryCode.dialCode;
                            });
                          },
                          initialSelection: _countryDialCode,
                          favorite: [_countryDialCode!],
                          showDropDownButton: true,
                          showCountryOnly: true,
                          showOnlyCountryWhenClosed: true,
                          showFlagDialog: true,
                          hideMainText: true,
                          showFlagMain: true,
                          dialogBackgroundColor: Theme.of(context).cardColor,
                          textStyle: rubikRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.titleMedium!.color,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(_countryDialCode ??'', style: rubikRegular),
                      ),

                      Flexible(
                        child: SizedBox(
                          height: 58,
                          child: CustomTextFieldWidget(
                            borderRadius: 0,
                            hintText: getTranslated('phone', context),
                            controller: _phoneController,
                            focusNode: _phoneNode,
                            nextFocus: _passwordNode,
                            inputType: TextInputType.phone,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), spreadRadius: 2, blurRadius: 12, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    getTranslated('account_information', context),
                    style: rubikBold,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  CustomTextFieldWidget(
                    hintText: getTranslated('email_address', context),
                    controller: _emailController,
                    focusNode: _emailNode,
                    nextFocus: _phoneNode,
                    inputType: TextInputType.emailAddress,
                    showTitle: true,
                    isShowBorder: true,
                    isRequired: true,
                    prefixIconUrl: Images.emailIcon,
                    isShowPrefixIcon: true,
                    borderRadius: Dimensions.radiusDefault,
                    onTap: (){setState(() {});},
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  CustomTextFieldWidget(
                    hintText: getTranslated('password', context),
                    controller: _passwordController,
                    focusNode: _passwordNode,
                    nextFocus: _confirmPasswordNode,
                    inputType: TextInputType.visiblePassword,
                    isPassword: true,
                    showTitle: true,
                    isShowSuffixIcon: true,
                    isShowBorder: true,
                    isRequired: true,
                    prefixIconUrl: Images.passwordIcon,
                    isShowPrefixIcon: true,
                    borderRadius: Dimensions.radiusDefault,
                    onTap: (){setState(() {});},
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  CustomTextFieldWidget(
                    hintText: getTranslated('confirm_password', context),
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordNode,
                    nextFocus: _identityNumberNode,
                    inputType: TextInputType.visiblePassword,
                    isPassword: true,
                    showTitle: true,
                    isShowSuffixIcon: true,
                    isShowBorder: true,
                    isRequired: true,
                    prefixIconUrl: Images.passwordIcon,
                    isShowPrefixIcon: true,
                    borderRadius: Dimensions.radiusDefault,
                    onTap: (){setState(() {});},
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), spreadRadius: 2, blurRadius: 12, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    getTranslated('branch_information', context),
                    style: rubikBold,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text(
                      getTranslated('branch', context),
                      style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                    ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  authProvider.branchList != null ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5))
                    ),
                    child: DropdownButton<int>(
                        hint: Text(
                          getTranslated('select_your_branch', context),
                          style: rubikRegular.copyWith(color: Theme.of(context).hintColor),
                        ),
                        value: authProvider.selectedBranchIndex,
                        items: branchIndexList.map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(authProvider.branchList![value].name!),
                          );
                        }).toList(),
                        onChanged: (value)=> authProvider.setBranchIndex(value!),
                        isExpanded: true,
                        underline: const SizedBox(),
                      ),
                  ) : const Center(child: CircularProgressIndicator()),

                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), spreadRadius: 2, blurRadius: 12, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    getTranslated('identity_information', context),
                    style: rubikBold,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Text(
                    getTranslated('identity_type', context),
                    style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.5))
                    ),
                    child: DropdownButton<String>(
                      value: authProvider.identityTypeList[authProvider.identityTypeIndex],
                      items: authProvider.identityTypeList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(getTranslated(value, context)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        authProvider.setIdentityTypeIndex(value, true);
                      },
                      isExpanded: true,
                      underline: const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  CustomTextFieldWidget(
                    hintText: getTranslated('identity_number', context),
                    controller: _identityNumberController,
                    focusNode: _identityNumberNode,
                    inputAction: TextInputAction.done,
                    showTitle: true,
                    isShowBorder: true,
                    isRequired: true,
                    borderRadius: Dimensions.radiusDefault,
                    onTap: (){setState(() {});},
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Container(
                    width: size.width,
                    decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)
                    ),
                    padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(
                          getTranslated('identity_image', context),
                          style: rubikBold,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Text('*', style: rubikRegular.copyWith(color: Theme.of(context).colorScheme.error))
                      ]),

                      Text(
                        '${getTranslated('upload_jpg_png_and_less_than', context)} 150 ${getTranslated('mb', context)}',
                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: authProvider.pickedIdentities.length+1,
                          itemBuilder: (context, index) {
                            XFile? file = index == authProvider.pickedIdentities.length ? null : authProvider.pickedIdentities[index];
                            if(index == authProvider.pickedIdentities.length) {
                              return InkWell(
                                onTap: () => authProvider.onPickDmImage(false, false),
                                child: Center(child: DottedBorder(
                                    options: RoundedRectDottedBorderOptions(
                                      dashPattern: const [8, 4],
                                      strokeWidth: 1.1,
                                      color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                                      radius: const Radius.circular(Dimensions.radiusDefault),
                                    ),
                                    child: Container(
                                      height: 100, width: 150,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      ),
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Image.asset(Images.galleryIcon, height: 24, width: 24),
                                        const SizedBox(height: Dimensions.paddingSizeSmall),

                                        Text(getTranslated('click_to_add', context), style: rubikMedium.copyWith(
                                            fontSize: Dimensions.fontSizeExtraSmall,
                                            color: Theme.of(context).hintColor.withValues(alpha: 0.6)
                                        ))
                                      ]),
                                    )
                                )),
                              );
                            }
                            return Container(
                              margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                              child: DottedBorder(
                                options: RoundedRectDottedBorderOptions(
                                  dashPattern: const [8, 4],
                                  strokeWidth: 1.1,
                                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                                  radius: const Radius.circular(Dimensions.radiusDefault),
                                ),
                                child: Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    child: kIsWeb ? Image.network(
                                      file!.path, width: 150, height: 100, fit: BoxFit.cover,
                                    ) : Image.file(
                                      File(file!.path), width: 150, height: 100, fit: BoxFit.cover,
                                    ),
                                  ),

                                  Positioned(
                                    right: 0, top: 0,
                                    child: InkWell(
                                      onTap: () => authProvider.onRemoveIdentityImage(index),
                                      child: const Padding(
                                        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                                        child: Icon(Icons.delete_forever, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      )
                    ]),
                  ),

                ]),
              ),

            ]),
          )),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30)],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeLarge),
              child: CustomButtonWidget(
                isLoading: authProvider.isLoading,
                btnTxt: getTranslated('submit', context),
                onTap: () => _addDeliveryMan(),
              ),
            ),
          ),

        ]);
      }),
    );
  }

  List<int> _getBranchIndexList(List<Branches> branchList) {
    List<int> branchIndexList = [];
    branchIndexList.add(0);

    for(int index=1; index<branchList.length; index++) {
      branchIndexList.add(index);
    }

    return branchIndexList;
  }

  void _addDeliveryMan() async {
    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

    String fName = _fNameController.text.trim();
    String lName = _lNameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String identityNumber = _identityNumberController.text.trim();

    PhoneNumber phoneNumber = PhoneNumber.parse(_countryDialCode! + phone);
    String numberWithCountryCode = phoneNumber.international;
    bool isValid = phoneNumber.isValid(type: PhoneNumberType.mobile);

    if(fName.isEmpty) {
      showCustomSnackBarHelper(getTranslated('enter_delivery_man_first_name', Get.context!));

    }else if(lName.isEmpty) {
      showCustomSnackBarHelper(getTranslated('enter_delivery_man_last_name', Get.context!));

    }else if(email.isEmpty) {
      showCustomSnackBarHelper(getTranslated('enter_delivery_man_email_address', Get.context!));

    }else if(EmailCheckerHelper.isNotValid(email)) {
      showCustomSnackBarHelper(getTranslated('enter_a_valid_email_address', Get.context!));

    }else if(phone.isEmpty) {
      showCustomSnackBarHelper(getTranslated('enter_delivery_man_phone_number', Get.context!));

    }else if(!isValid) {
      showCustomSnackBarHelper(getTranslated('enter_a_valid_phone_number', Get.context!));

    }else if(password.isEmpty) {
      showCustomSnackBarHelper(getTranslated('enter_password_for_delivery_man', Get.context!));

    }else if(password.length < 8) {
      showCustomSnackBarHelper(getTranslated('password_should_be', Get.context!));

    }else if(confirmPassword != password) {
      showCustomSnackBarHelper(getTranslated('password_does_not_matched', Get.context!));

    }else if(identityNumber.isEmpty) {
      showCustomSnackBarHelper(getTranslated('enter_delivery_man_identity_number', Get.context!));

    }else if(authProvider.pickedImage == null) {
      showCustomSnackBarHelper(getTranslated('upload_delivery_man_image', Get.context!));

    }else {
      authProvider.registerDeliveryMan(DeliveryManBodyModel(
        fName: fName, lName: lName,
        password: password, phone: numberWithCountryCode,
        email: email, identityNumber: identityNumber,
        identityType: authProvider.identityTypeList[authProvider.identityTypeIndex],
        branchId: authProvider.branchList![authProvider.selectedBranchIndex!].id.toString(),
      ));
    }
  }
}

