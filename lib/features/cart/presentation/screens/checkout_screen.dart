import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  bool isCashOnDelivery = true; // "Cash", else "Card"
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onPlaceOrder() async {
    // Basic validation
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // According to API spec: payment_method -> "Cash" or "Card" (string?)
    // The spec says "payment_method": "..."
    final paymentMethod = isCashOnDelivery ? "Cash" : "Card";

    try {
      await ref
          .read(cartProvider.notifier)
          .checkout(
            _nameController.text.trim(),
            _phoneController.text.trim(),
            _addressController.text.trim(),
            _countryController.text.trim(),
            _cityController.text.trim(),
            paymentMethod,
          );

      if (mounted) {
        context.go(AppRoutes.orderSuccess);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Order failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Shipping Address",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _nameController,
                label: "Full Name",
                hintText: "Enter Name",
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _countryController,
                      label: "Country",
                      hintText: "Country",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: "City",
                      hintText: "City",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _phoneController,
                label: "Phone Number",
                hintText: "Phone Number",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _addressController,
                label: "Address",
                hintText: "Street Address",
              ),

              const SizedBox(height: 30),
              const Text(
                "Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 15),

              // Payment Options
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isCashOnDelivery = true),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isCashOnDelivery
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.grey,
                          border: Border.all(
                            color: isCashOnDelivery
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.money, color: AppColors.textMain),
                            SizedBox(height: 5),
                            Text("Cash", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isCashOnDelivery = false),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: !isCashOnDelivery
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.grey,
                          border: Border.all(
                            color: !isCashOnDelivery
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.credit_card, color: AppColors.textMain),
                            SizedBox(height: 5),
                            Text("Card", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              if (!isCashOnDelivery) ...[
                // Mock card fields - not used in API currently but kept for UI
                const CustomTextField(
                  label: "Card Number",
                  hintText: "1234 5678 1234 5678",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(
                      child: CustomTextField(
                        label: "Exp. Date",
                        hintText: "MM/YY",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(label: "CVV", hintText: "123"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const CustomTextField(
                  label: "Cardholder Name",
                  hintText: "Enter Name",
                ),
                const SizedBox(height: 20),
              ],

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(text: "Place Order", onPressed: _onPlaceOrder),
            ],
          ),
        ),
      ),
    );
  }
}
