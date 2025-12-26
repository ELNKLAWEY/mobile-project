import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/home_providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _startVoiceSearch() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${error.errorMsg}')));
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              // Navigate to search screen with the recognized text
              context.push(AppRoutes.search, extra: result.recognizedWords);
              setState(() => _isListening = false);
            }
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(brandsProvider);
    final neArrivalsAsync = ref.watch(newArrivalsProvider);

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header with User Info
            Consumer(
              builder: (context, ref, child) {
                final userAsync = ref.watch(authStateProvider);
                final user = userAsync.valueOrNull;

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.primary),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 40,
                          )
                        : null,
                  ),
                  accountName: Text(
                    user?.name ?? "Guest",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(user?.email ?? "Sign in to see details"),
                );
              },
            ),

            // Menu Items
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text("Password"),
              subtitle: const Text("Reset Password"),
              onTap: () => context.push(AppRoutes.forgotPassword),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text("Orders"),
              onTap: () => context.push(AppRoutes.orders),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text("Whishlist"), //Wishlist as requested
              onTap: () => context.push(AppRoutes.wishlist),
            ),

            // Dark Mode Switch
            Consumer(
              builder: (context, ref, child) {
                final themeMode = ref.watch(themeProvider);
                return SwitchListTile(
                  title: const Text("Dark Mode"),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                );
              },
            ),

            const Spacer(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh synchronous provider first
          ref.refresh(cartItemCountProvider);
          // Then wait for async providers
          await Future.wait([
            ref.refresh(brandsProvider.future),
            ref.refresh(newArrivalsProvider.future),
          ]);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_open_rounded),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.grey,
                        shape: const CircleBorder(),
                      ),
                    ),
                    IconButton(
                      icon: Badge(
                        label: Consumer(
                          builder: (context, ref, child) {
                            final count = ref.watch(cartItemCountProvider);
                            return Text(count.toString());
                          },
                        ),
                        isLabelVisible:
                            true, // We can condition this inside builder if needed, or wrap Badge
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      onPressed: () => context.go(AppRoutes.cart),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.grey,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Welcome Text
                Text(
                  "Hello",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  "Welcome to Laza.",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.search),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Search...",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _startVoiceSearch,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? AppColors.error
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Brands
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Choose Brand",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.allBrands),
                      child: const Text(
                        "View All",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 50,
                  child: brandsAsync.when(
                    data: (brands) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: brands.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final brand = brands[index];
                        return GestureDetector(
                          onTap: () {
                            context.push(AppRoutes.brandProducts, extra: brand);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: brand.image != null
                                      ? Image.network(
                                          brand.image!,
                                          width: 30,
                                          height: 30,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => const Icon(
                                                FontAwesomeIcons.bagShopping,
                                                size: 20,
                                              ),
                                        )
                                      : const Icon(
                                          FontAwesomeIcons.bagShopping,
                                          size: 20,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  brand.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
                const SizedBox(height: 20),

                // New Arrivals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "New Arrival",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.allNewArrivals),
                      child: const Text(
                        "View All",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                neArrivalsAsync.when(
                  data: (products) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65, // Adjusted aspect ratio
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
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
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
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
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
