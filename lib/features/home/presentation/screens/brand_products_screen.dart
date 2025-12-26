import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/brand_model.dart';
import '../providers/brand_provider.dart';
import '../../../../features/wishlist/presentation/providers/wishlist_provider.dart';
import '../../../../features/product/data/models/product_model.dart';

enum SortOption { priceAsc, priceDesc, nameAsc, nameDesc }

class BrandProductsScreen extends ConsumerStatefulWidget {
  final BrandModel brand;

  const BrandProductsScreen({super.key, required this.brand});

  @override
  ConsumerState<BrandProductsScreen> createState() =>
      _BrandProductsScreenState();
}

class _BrandProductsScreenState extends ConsumerState<BrandProductsScreen> {
  SortOption _currentSortOption = SortOption.nameAsc;

  List<ProductModel> _sortProducts(List<ProductModel> products) {
    List<ProductModel> sorted = List.from(products);
    switch (_currentSortOption) {
      case SortOption.priceAsc:
        sorted.sort((a, b) {
          final pA = double.tryParse(a.price.toString()) ?? 0;
          final pB = double.tryParse(b.price.toString()) ?? 0;
          return pA.compareTo(pB);
        });
        break;
      case SortOption.priceDesc:
        sorted.sort((a, b) {
          final pA = double.tryParse(a.price.toString()) ?? 0;
          final pB = double.tryParse(b.price.toString()) ?? 0;
          return pB.compareTo(pA);
        });
        break;
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
        break;
    }
    return sorted;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sort By",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildSortOption(SortOption.nameAsc, "Name (A-Z)"),
              _buildSortOption(SortOption.nameDesc, "Name (Z-A)"),
              _buildSortOption(SortOption.priceAsc, "Price (Low to High)"),
              _buildSortOption(SortOption.priceDesc, "Price (High to Low)"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(SortOption option, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentSortOption = option;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              _currentSortOption == option
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _currentSortOption == option
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: _currentSortOption == option
                    ? AppColors.textMain
                    : AppColors.textSecondary,
                fontWeight: _currentSortOption == option
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsByBrandProvider(widget.brand.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.brand.name,
          style: GoogleFonts.inter(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: widget.brand.image != null
                ? Image.network(
                    widget.brand.image!,
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${productsAsync.valueOrNull?.length ?? 0} Items",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      "Available in stock",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sort, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          "Sort",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 60,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No products found for this brand.",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final sortedProducts = _sortProducts(products);

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: sortedProducts.length,
                    itemBuilder: (context, index) {
                      final product = sortedProducts[index];
                      return GestureDetector(
                        onTap: () {
                          context.push(
                            AppRoutes.productDetails,
                            extra: product,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: AppColors.grey,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      product.image,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: AppColors.textSecondary,
                                              ),
                                            );
                                          },
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Consumer(
                                        builder: (context, ref, child) {
                                          final wishlist =
                                              ref
                                                  .watch(wishlistProvider)
                                                  .valueOrNull ??
                                              [];
                                          final isWishlisted = wishlist.any(
                                            (item) => item.id == product.id,
                                          );
                                          return InkWell(
                                            onTap: () {
                                              ref
                                                  .read(
                                                    wishlistProvider.notifier,
                                                  )
                                                  .toggleWishlist(product);
                                            },
                                            child: Icon(
                                              isWishlisted
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isWishlisted
                                                  ? Colors.red
                                                  : AppColors.textMain,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "\$${product.price}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                error: (err, stack) => Center(child: Text('Error: $err')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
