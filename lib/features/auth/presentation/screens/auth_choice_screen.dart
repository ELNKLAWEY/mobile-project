import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Title / Logo Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Let's Get Started",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              const SizedBox(height: 30),

              // Login & Create Account
              CustomButton(
                text: "Login",
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 15),
              CustomButton(
                text: "Create an Account",
                backgroundColor: AppColors.primaryDark,
                onPressed: () => context.push(AppRoutes.register),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
