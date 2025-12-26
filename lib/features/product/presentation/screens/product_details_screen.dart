import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/product_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';

class ProductDetailsScreen extends ConsumerWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: AppColors.white),
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Consumer(
                builder: (context, ref, child) {
                  final count = ref.watch(cartItemCountProvider);
                  return Text(count.toString());
                },
              ),
              isLabelVisible: true,
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.textMain,
              ),
            ),
            onPressed: () => context.go(AppRoutes.cart),
            style: IconButton.styleFrom(backgroundColor: AppColors.white),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          // Image Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Image.network(
              product.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.grey,
                child: const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 50,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.brandName ?? "Product",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        "Price",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      Text(
                        "\$${product.price}",
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final wishlist =
                            ref.watch(wishlistProvider).valueOrNull ?? [];
                        final isWishlisted = wishlist.any(
                          (item) => item.id == product.id,
                        );
                        return InkWell(
                          onTap: () {
                            ref
                                .read(wishlistProvider.notifier)
                                .toggleWishlist(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.grey.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isWishlisted
                                  ? Colors.red
                                  : AppColors.textMain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Description
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.description,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Reviews",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          // Static Review for now
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?img=12',
                              ),
                            ),
                            title: const Text(
                              "Ronald Richards",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: const [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                Icon(
                                  Icons.star_half,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 5),
                                Text("4.5 Rating"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Button
                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Add to Cart",
                    onPressed: () {
                      ref.read(cartProvider.notifier).addToCart(product.id, 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Added to cart")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
