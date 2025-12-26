import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_flutter_app/core/theme/app_colors.dart';
import 'package:my_flutter_app/core/router/app_routes.dart';
import 'package:my_flutter_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_flutter_app/core/theme/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppColors.primary, size: 40),
            ),
            accountName: Text(
              userAsync.valueOrNull?.name ?? "Guest",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              userAsync.valueOrNull?.email ?? "Sign in to see details",
            ),
          ),

          // Menu Items
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text("Password"),
            subtitle: const Text("Reset Password"),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.forgotPassword);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text("Orders"),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.orders);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text("Wishlist"),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.wishlist);
            },
          ),

          // Dark Mode Switch
          SwitchListTile(
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),

          const Spacer(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              "Logout",
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              ref.read(authStateProvider.notifier).logout();
              Navigator.pop(context);
              context.go(AppRoutes.authChoice);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
