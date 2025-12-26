import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/auth_choice_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/brand_products_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/home/presentation/screens/all_brands_screen.dart';
import '../../features/home/presentation/screens/all_new_arrivals_screen.dart';
import '../../features/home/data/models/brand_model.dart';

import '../../features/product/presentation/screens/product_details_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/cart/presentation/screens/order_success_screen.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../features/cart/presentation/screens/orders_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.authChoice,
        builder: (context, state) => const AuthChoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Main Shell Route (Bottom Nav)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Wishlist Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wishlist,
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          // Cart Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          // Orders Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) {
          final initialQuery = state.extra as String?;
          return SearchScreen(initialQuery: initialQuery);
        },
      ),
      GoRoute(
        path: AppRoutes.productDetails,
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return ProductDetailsScreen(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.brandProducts,
        builder: (context, state) {
          final brand = state.extra as BrandModel;
          return BrandProductsScreen(brand: brand);
        },
      ),
      GoRoute(
        path: AppRoutes.allBrands,
        builder: (context, state) => const AllBrandsScreen(),
      ),
      GoRoute(
        path: AppRoutes.allNewArrivals,
        builder: (context, state) => const AllNewArrivalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        builder: (context, state) => const OrderSuccessScreen(),
      ),
    ],
  );
});
