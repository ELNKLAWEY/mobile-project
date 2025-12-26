import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_flutter_app/core/router/app_routes.dart';
import 'package:my_flutter_app/core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Check auth state after a short delay to allow auth check to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasNavigated) {
        _checkAndNavigate();
      }
    });
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        if (user != null) {
          // User is logged in, go to home
          context.go(AppRoutes.home);
        } else {
          // User is not logged in, go to auth choice
          context.go(AppRoutes.authChoice);
        }
      },
      loading: () {
        // Still loading, check again after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_hasNavigated) {
            _checkAndNavigate();
          }
        });
      },
      error: (error, stack) {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        // On error, go to auth choice
        context.go(AppRoutes.authChoice);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to auth state changes in case state changes while on splash
    ref.listen<AsyncValue>(
      authStateProvider,
      (previous, next) {
        if (!_hasNavigated) {
          _checkAndNavigate();
        }
      },
    );
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Laza",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
