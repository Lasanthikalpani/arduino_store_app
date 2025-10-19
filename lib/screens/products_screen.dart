// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    // Load products when screen initializes
    // Load products and cart when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productsProvider = Provider.of<ProductsProvider>(
        context,
        listen: false,
      );
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // Load products first, then cart (so cart can access product details)
      productsProvider.loadProducts().then((_) {
        cartProvider.loadCart();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arduino Store'),
        backgroundColor: Colors.orange,
        actions: [
          // Cart Icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartProvider.itemCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // User menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
              } else if (value == 'profile') {
                _showUserProfile(context, authProvider);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: productsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productsProvider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${productsProvider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => productsProvider.loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: productsProvider.products.length,
              itemBuilder: (context, index) {
                final product = productsProvider.products[index];
                return ProductCard(product: product);
              },
            ),
    );
  }

  void _showUserProfile(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${authProvider.user?.fullName ?? 'N/A'}'),
            Text('Email: ${authProvider.user?.email ?? 'N/A'}'),
            Text('Phone: ${authProvider.user?.phone ?? 'N/A'}'),
            Text('Address: ${authProvider.user?.address ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// In lib/screens/products_screen.dart - UPDATE the ProductCard:

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.memory,
                        size: 50,
                        color: Colors.grey,
                      );
                    },
                  )
                : const Icon(Icons.memory, size: 50, color: Colors.grey),
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Add to Cart Button - FIXED: Use product.id instead of product
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      cartProvider.addToCart(
                        product.id,
                        1,
                      ); // FIX: Use product.id
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${product.name} to cart'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
