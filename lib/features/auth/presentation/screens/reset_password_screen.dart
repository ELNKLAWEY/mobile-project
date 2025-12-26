import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

enum ResetPasswordStep {
  phone,
  otp,
  password,
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends ConsumerState<ResetPasswordScreen> {
  ResetPasswordStep _currentStep = ResetPasswordStep.phone;
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(4, (_) => FocusNode());
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';
  String _resetToken = '';

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneAndSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.checkPhoneAndSendOtp(phone);
      setState(() {
        _phoneNumber = phone;
        _currentStep = ResetPasswordStep.otp;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      setState(() {
        _errorMessage = 'Please enter the complete OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final resetToken = await repository.verifyOtp(_phoneNumber, otp);
      setState(() {
        _resetToken = resetToken;
        _currentStep = ResetPasswordStep.password;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    if (password.isEmpty || passwordConfirm.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (password != passwordConfirm) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resetPassword(
        _phoneNumber,
        password,
        passwordConfirm,
        _resetToken,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    }
  }

  void _onOtpDeleted(int index) {
    if (index > 0 && _otpControllers[index].text.isEmpty) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 20),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textMain,
            ),
            onPressed: () {
              if (_currentStep == ResetPasswordStep.phone) {
                context.pop();
              } else {
                setState(() {
                  if (_currentStep == ResetPasswordStep.otp) {
                    _currentStep = ResetPasswordStep.phone;
                  } else if (_currentStep == ResetPasswordStep.password) {
                    _currentStep = ResetPasswordStep.otp;
                  }
                  _errorMessage = null;
                });
              }
            },
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Reset Password",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: Icon(
                Icons.lock_reset,
                size: 100,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 50),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildCurrentStep(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case ResetPasswordStep.phone:
        return _buildPhoneStep();
      case ResetPasswordStep.otp:
        return _buildOtpStep();
      case ResetPasswordStep.password:
        return _buildPasswordStep();
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Please enter your phone number. You will receive an OTP code to reset your password.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 50),
        CustomTextField(
          controller: _phoneController,
          label: "Phone Number",
          hintText: "Enter your phone number",
          keyboardType: TextInputType.phone,
        ),
        const Spacer(),
        CustomButton(
          text: _isLoading ? "Sending..." : "Send OTP",
          onPressed: _isLoading ? null : _checkPhoneAndSendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter the 4-digit OTP code sent to $_phoneNumber",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 60,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.grey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) => _onOtpChanged(index, value),
                onSubmitted: (value) {
                  if (index < 3) {
                    FocusScope.of(context)
                        .requestFocus(_otpFocusNodes[index + 1]);
                  } else {
                    _verifyOtp();
                  }
                },
                onEditingComplete: () => _onOtpDeleted(index),
              ),
            );
          }),
        ),
        const Spacer(),
        CustomButton(
          text: _isLoading ? "Verifying..." : "Verify OTP",
          onPressed: _isLoading ? null : _verifyOtp,
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter your new password",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 50),
        CustomTextField(
          controller: _passwordController,
          label: "New Password",
          hintText: "Enter new password",
          isPassword: true,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: _passwordConfirmController,
          label: "Confirm Password",
          hintText: "Confirm new password",
          isPassword: true,
        ),
        const Spacer(),
        CustomButton(
          text: _isLoading ? "Resetting..." : "Reset Password",
          onPressed: _isLoading ? null : _resetPassword,
        ),
      ],
    );
  }
}
