import 'package:flutter/material.dart';
import 'package:flutter_grocery/common/models/cart_model.dart';
import 'package:flutter_grocery/common/models/product_model.dart';
import 'package:flutter_grocery/common/providers/cart_provider.dart';
import 'package:flutter_grocery/common/widgets/custom_directionality_widget.dart';
import 'package:flutter_grocery/common/widgets/custom_image_widget.dart';
import 'package:flutter_grocery/features/splash/providers/splash_provider.dart';
import 'package:flutter_grocery/helper/custom_snackbar_helper.dart';
import 'package:flutter_grocery/helper/price_converter_helper.dart';
import 'package:flutter_grocery/helper/responsive_helper.dart';
import 'package:flutter_grocery/helper/route_helper.dart';
import 'package:flutter_grocery/localization/language_constraints.dart';
import 'package:flutter_grocery/utill/color_resources.dart';
import 'package:flutter_grocery/utill/dimensions.dart';
import 'package:flutter_grocery/utill/styles.dart';
import 'package:provider/provider.dart';

/// Zepto-inspired compact product card with CTA-first layout.
class ZeptoStyleProductCard extends StatelessWidget {
  final Product product;

  const ZeptoStyleProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final discountValue = PriceConverterHelper.convertProductDiscount(
      price: product.price,
      discount: product.discount,
      discountType: product.discountType,
      categoryDiscount: product.categoryDiscount,
    );

    final bool hasVariations = product.variations != null && (product.variations?.isNotEmpty ?? false);

    return Consumer<CartProvider>(builder: (context, cartProvider, _) {
      final baseUrls = Provider.of<SplashProvider>(context, listen: false).baseUrls;
      final imagePath = (product.image?.isNotEmpty ?? false) ? product.image![0] : '';
      final imageUrl = baseUrls?.productImageUrl != null ? '${baseUrls?.productImageUrl}/$imagePath' : imagePath;
      // Build base cart model for quick-add (no variations).
      CartModel? cartModel;
      int? cartIndex;
      bool isInCart = false;
      int? stock = product.totalStock;
      double unitPrice = product.price ?? 0;

      if (!hasVariations) {
        cartModel = CartModel(
          product.id,
          (product.image?.isNotEmpty ?? false) ? product.image![0] : '',
          product.name,
          unitPrice,
          discountValue.discount,
          1,
          null,
          (unitPrice - (discountValue.discount ?? 0)),
          ((discountValue.discount ?? 0) - PriceConverterHelper.convertWithDiscount(discountValue.discount, product.tax, product.taxType)!),
          product.capacity,
          product.unit,
          stock,
          product,
        );
        cartIndex = cartProvider.isExistInCart(cartModel);
        isInCart = cartIndex != null;
      }

      return Container(
        width: 170,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => RouteHelper.getProductDetailsRoute(productId: product.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + discount badge
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomImageWidget(
                        image: imageUrl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if ((product.price ?? 0) > (discountValue.discount ?? product.price ?? 0))
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.discountType == 'percent'
                              ? '-${product.discount?.toStringAsFixed(0) ?? ''}%'
                              : '-${PriceConverterHelper.convertPrice(context, product.discount)}',
                          style: poppinsMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // CTA-first: add button or stepper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: hasVariations
                    ? _AddButton(
                        label: getTranslated('add', context),
                        onTap: () => RouteHelper.getProductDetailsRoute(productId: product.id),
                      )
                    : isInCart
                        ? _QuantityStepper(cartIndex: cartIndex!, stock: stock, product: product)
                        : _AddButton(
                            label: getTranslated('add', context),
                            onTap: () {
                              if ((stock ?? 0) < 1) {
                                showCustomSnackBarHelper(getTranslated('out_of_stock', context), snackBarStatus: SnackBarStatus.info);
                                return;
                              }
                              cartProvider.addToCart(cartModel!);
                              showCustomSnackBarHelper(getTranslated('added_to_cart', context), isError: false);
                            },
                          ),
              ),

              const SizedBox(height: 6),

              // Price row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomDirectionalityWidget(
                      child: Text(
                        PriceConverterHelper.convertPrice(context, discountValue.discount ?? (product.price ?? 0)),
                        style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if ((product.price ?? 0) > (discountValue.discount ?? product.price ?? 0))
                      CustomDirectionalityWidget(
                        child: Text(
                          PriceConverterHelper.convertPrice(context, product.price),
                          style: poppinsRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Name and meta
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  product.name ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: poppinsMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ),

              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      '${product.capacity ?? ''} ${product.unit ?? ''}',
                      style: poppinsRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const Spacer(),
                    if ((product.rating?.isNotEmpty ?? false) && product.rating![0].average != null)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: ColorResources.ratingColor),
                          const SizedBox(width: 2),
                          Text(
                            product.rating![0].average!.toStringAsFixed(1),
                            style: poppinsRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    });
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B383),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(label.toUpperCase(), style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int cartIndex;
  final int? stock;
  final Product product;

  const _QuantityStepper({required this.cartIndex, required this.stock, required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(builder: (context, cart, _) {
      final quantity = cart.cartList[cartIndex].quantity ?? 1;
      final maxQty = cart.cartList[cartIndex].product?.maximumOrderQuantity;

      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            _stepButton(context, icon: Icons.remove, onTap: () {
              if (quantity > 1) {
                cart.setCartQuantity(false, cartIndex, context: context, showMessage: true);
              } else {
                cart.removeItemFromCart(cartIndex, context);
              }
            }),
            Expanded(
              child: Center(
                child: Text(
                  '$quantity',
                  style: poppinsSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
              ),
            ),
            _stepButton(context, icon: Icons.add, onTap: () {
              if ((maxQty != null && quantity >= maxQty) || (stock != null && quantity >= (stock ?? 0))) {
                showCustomSnackBarHelper(getTranslated('there_is_nt_enough_quantity_on_stock', context), snackBarStatus: SnackBarStatus.info);
                return;
              }
              cart.setCartQuantity(true, cartIndex, showMessage: false, context: context);
            }),
          ],
        ),
      );
    });
  }

  Widget _stepButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
      ),
    );
  }
}