import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/app_routes.dart';
import 'package:my_flutter_app/core/theme/app_colors.dart';
import 'package:my_flutter_app/core/widgets/custom_button.dart';
import 'package:my_flutter_app/core/widgets/custom_text_field.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    await ref
        .read(authStateProvider.notifier)
        .register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            context.go(AppRoutes.home);
          }
        },
        error: (err, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err.toString())));
        },
        loading: () {},
      );
    });

    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Sign Up",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              // Form
              CustomTextField(
                controller: _nameController,
                label: "Full Name",
                hintText: "Enter your full name",
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _emailController,
                label: "Email Address",
                hintText: "Enter your email address",
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _phoneController,
                label: "Phone Number",
                hintText: "Enter your phone number",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _passwordController,
                label: "Password",
                hintText: "Enter your password",
                isPassword: true,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                hintText: "Confirm your password",
                isPassword: true,
              ),

              const SizedBox(height: 50),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(text: "Sign Up", onPressed: _onRegister),
            ],
          ),
        ),
      ),
    );
  }
}
