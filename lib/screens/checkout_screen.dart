import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String _paymentMethod = 'credit_card';

  // Form controllers
  final _shippingAddressController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingZipController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  void _prefillUserData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      _shippingAddressController.text = authProvider.user!.address;
      _cardNameController.text = authProvider.user!.fullName;
    }
  }

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _shippingCityController.dispose();
    _shippingZipController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  // In CheckoutScreen, update the _placeOrder method:
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await ApiService.createOrderMock(
        shippingAddress: _shippingAddressController.text,
        city: _shippingCityController.text,
        zipCode: _shippingZipController.text,
        paymentMethod: _paymentMethod,
        totalAmount: _calculatedTotal,
      );

      if (response['success'] == true) {
        // Clear cart on success
        final cartProvider = context.read<CartProvider>();
        await cartProvider.clearCart();

        // Show success dialog
        if (mounted) {
          _showOrderSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order failed: ${response['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showOrderSuccessDialog() {
    final cartProvider = context.read<CartProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 8),
            Text('Order Confirmed!', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thank you for your purchase!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildOrderDetailRow(
                'Order Total',
                '\$${_calculatedTotal.toStringAsFixed(2)}',
              ),
              _buildOrderDetailRow(
                'Items Ordered',
                '${cartProvider.itemCount} items',
              ),
              _buildOrderDetailRow('Shipping to', _shippingCityController.text),
              _buildOrderDetailRow('Payment Method', _getPaymentMethodText()),
              const SizedBox(height: 12),
              const Text(
                'Your order will be shipped within 2-3 business days. You will receive a confirmation email shortly.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate all the way back to products screen
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getPaymentMethodText() {
    switch (_paymentMethod) {
      case 'credit_card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return 'Credit Card';
    }
  }

  double get _calculatedTotal {
    final cartProvider = context.read<CartProvider>();
    final subtotal = cartProvider.totalPrice;
    const shipping = 5.99;
    final tax = subtotal * 0.08;
    return subtotal + shipping + tax;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.orange,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Section
                    _buildOrderSummary(cartProvider),
                    const SizedBox(height: 24),

                    // Shipping Information
                    _buildShippingSection(authProvider),
                    const SizedBox(height: 24),

                    // Payment Method
                    _buildPaymentSection(),
                    const SizedBox(height: 24),

                    // Place Order Button
                    _buildPlaceOrderButton(cartProvider),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...cartProvider.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} (x${item.quantity})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            _buildTotalRow('Subtotal', cartProvider.totalPrice),
            _buildTotalRow('Shipping', 5.99),
            _buildTotalRow('Tax', cartProvider.totalPrice * 0.08),
            const Divider(height: 20),
            _buildTotalRow('Total', _calculatedTotal, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.orange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection(AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shippingAddressController,
              decoration: const InputDecoration(
                labelText: 'Shipping Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter shipping address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _shippingCityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _shippingZipController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP Code *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter ZIP code';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Payment Method Selection
            Column(
              children: [
                _buildPaymentMethodTile(
                  'Credit/Debit Card',
                  'credit_card',
                  Icons.credit_card,
                ),
                _buildPaymentMethodTile('PayPal', 'paypal', Icons.payment),
                _buildPaymentMethodTile('Cash on Delivery', 'cod', Icons.money),
              ],
            ),
            const SizedBox(height: 16),

            // Card Details (only show for credit card)
            if (_paymentMethod == 'credit_card') ..._buildCreditCardForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String title, String value, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title)],
      ),
      value: value,
      groupValue: _paymentMethod,
      onChanged: (String? value) {
        setState(() {
          _paymentMethod = value!;
        });
      },
    );
  }

  List<Widget> _buildCreditCardForm() {
    return [
      TextFormField(
        controller: _cardNameController,
        decoration: const InputDecoration(
          labelText: 'Cardholder Name *',
          border: OutlineInputBorder(),
        ),
        validator: _paymentMethod == 'credit_card'
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              }
            : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _cardNumberController,
        decoration: const InputDecoration(
          labelText: 'Card Number *',
          border: OutlineInputBorder(),
          hintText: '1234 5678 9012 3456',
        ),
        keyboardType: TextInputType.number,
        validator: _paymentMethod == 'credit_card'
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                if (value.length != 16) {
                  return 'Please enter valid card number';
                }
                return null;
              }
            : null,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _cardExpiryController,
              decoration: const InputDecoration(
                labelText: 'MM/YY *',
                border: OutlineInputBorder(),
                hintText: '12/25',
              ),
              validator: _paymentMethod == 'credit_card'
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter expiry date';
                      }
                      return null;
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _cardCvvController,
              decoration: const InputDecoration(
                labelText: 'CVV *',
                border: OutlineInputBorder(),
                hintText: '123',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              validator: _paymentMethod == 'credit_card'
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter CVV';
                      }
                      if (value.length != 3) {
                        return 'Please enter valid CVV';
                      }
                      return null;
                    }
                  : null,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildPlaceOrderButton(CartProvider cartProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'PLACE ORDER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
