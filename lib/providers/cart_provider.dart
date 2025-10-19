// lib/providers/cart_provider.dart - FIXED VERSION
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // Store product cache to avoid repeated API calls
  final Map<String, Product> _productCache = {};

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getCart();
      
      print('🛒 Cart API Response: $response');
      
      if (response['success'] == true) {
        final cartData = response['cart'];
        print('📦 Cart data structure: $cartData');
        
        if (cartData['items'] != null) {
          final itemsData = cartData['items'] as List;
          print('🛍️ Cart items count: ${itemsData.length}');
          
          // Clear current items
          _items = [];
          
          // Fetch product details for each cart item
          for (var itemData in itemsData) {
            try {
              final productId = itemData['productId'];
              print('🔍 Processing cart item for product: $productId');
              
              // Get product details
              final product = await _getProductDetails(productId);
              
              // Create CartItem with product details
              final cartItem = CartItem(
                id: itemData['id'] ?? productId,
                productId: productId,
                productName: product?.name ?? 'Product $productId',
                price: product?.price ?? 0.0,
                quantity: itemData['quantity'] ?? 1,
                imageUrl: product?.imageUrl ?? '',
              );
              
              _items.add(cartItem);
              print('✅ Added cart item: ${cartItem.productName} - \$${cartItem.price}');
            } catch (e) {
              print('❌ Error processing cart item: $e');
              // Create fallback cart item
              final cartItem = CartItem(
                id: itemData['id'] ?? itemData['productId'],
                productId: itemData['productId'],
                productName: 'Product ${itemData['productId']}',
                price: 0.0,
                quantity: itemData['quantity'] ?? 1,
                imageUrl: '',
              );
              _items.add(cartItem);
            }
          }
          
          print('✅ Loaded ${_items.length} cart items with details');
          for (var item in _items) {
            print('   - ${item.productName}: \$${item.price} x ${item.quantity} = \$${item.totalPrice}');
          }
        }
        _error = null;
      } else {
        _error = response['error'] ?? 'Failed to load cart';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to get product details
  Future<Product?> _getProductDetails(String productId) async {
    // Check cache first
    if (_productCache.containsKey(productId)) {
      return _productCache[productId];
    }
    
    try {
      // Fetch all products and find the matching one
      final productsResponse = await ApiService.getProducts();
      if (productsResponse['success'] == true) {
        final productsData = productsResponse['products'] as List;
        for (var productJson in productsData) {
          final product = Product.fromJson(productJson);
          _productCache[product.id] = product; // Cache the product
          if (product.id == productId) {
            print('🎯 Found product: ${product.name} - \$${product.price}');
            return product;
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching product details: $e');
    }
    
    print('⚠️ Product not found: $productId');
    return null;
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final response = await ApiService.addToCart(productId, quantity);
      
      if (response['success'] == true) {
        // Reload cart to get updated state from server
        await loadCart();
      } else {
        _error = response['error'] ?? 'Failed to add item to cart';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(itemId);
      return;
    }

    try {
      final response = await ApiService.updateCartItem(itemId, newQuantity);
      
      if (response['success'] == true) {
        await loadCart();
      } else {
        _error = response['error'] ?? 'Failed to update cart';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      final response = await ApiService.removeFromCart(itemId);
      
      if (response['success'] == true) {
        await loadCart();
      } else {
        _error = response['error'] ?? 'Failed to remove item from cart';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    // Remove all items one by one
    for (final item in List.from(_items)) {
      await removeFromCart(item.id);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        id: '',
        productId: '',
        productName: '',
        price: 0,
        quantity: 0,
        imageUrl: '',
      ),
    );
    return item.quantity;
  }
}