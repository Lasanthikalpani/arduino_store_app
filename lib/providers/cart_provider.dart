// lib/providers/cart_provider.dart - COMPLETELY FIXED VERSION
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get totalPrice => price * quantity;

  @override
  String toString() {
    return 'CartItem{productName: $productName, price: $price, quantity: $quantity, total: $totalPrice}';
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  double _cartTotal = 0.0;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get cartTotal => _cartTotal;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  Future<void> loadCart() async {
    // ✅ FIXED: Proper boolean check with await
    final bool isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn == false) {
      _error = 'Please login to view cart';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getCart();
      
      print('🛒 Cart API Response: $response');
      
      // ✅ FIXED: Proper boolean check
      final bool success = response['success'] == true;
      
      if (success) {
        final cartData = response['cart'];
        print('📦 Cart data: $cartData');
        
        _items = [];
        
        if (cartData != null && cartData['items'] is List) {
          final itemsData = cartData['items'] as List;
          print('🛍️ Raw cart items: $itemsData');
          
          for (var itemData in itemsData) {
            try {
              final productId = itemData['productId']?.toString() ?? '';
              final productName = itemData['name']?.toString() ?? 'Unknown Product';
              final price = (itemData['price'] ?? 0.0).toDouble();
              final quantity = (itemData['quantity'] ?? 1).toInt();
              final imageUrl = itemData['imageUrl']?.toString() ?? '';
              
              final cartItem = CartItem(
                id: productId,
                productId: productId,
                productName: productName,
                price: price,
                quantity: quantity,
                imageUrl: imageUrl,
              );
              
              _items.add(cartItem);
              print('✅ Added to cart: $cartItem');
            } catch (e) {
              print('❌ Error parsing cart item: $e - Data: $itemData');
            }
          }
          
          _cartTotal = (cartData['total'] ?? 0.0).toDouble();
        } else {
          print('📦 Cart is empty or items is null');
          _items = [];
          _cartTotal = 0.0;
        }
        
        print('🎯 Final cart: ${_items.length} items, total: \$$_cartTotal');
      } else {
        _error = response['error'] ?? 'Failed to load cart';
        print('❌ Cart load error: $_error');
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('❌ Cart load exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    // ✅ FIXED: Proper boolean check with await
    final bool isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn == false) {
      _error = 'Please login to add items to cart';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.addToCart(productId, quantity);
      
      print('➕ Add to cart response: $response');
      
      // ✅ FIXED: Proper boolean check
      final bool success = response['success'] == true;
      
      if (success) {
        await loadCart();
      } else {
        _error = response['error'] ?? 'Failed to add item to cart';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    // ✅ FIXED: Proper boolean check with await
    final bool isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn == false) {
      _error = 'Please login to update cart';
      notifyListeners();
      return;
    }

    if (newQuantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.updateCartItem(productId, newQuantity);
      
      print('✏️ Update cart response: $response');
      
      // ✅ FIXED: Proper boolean check
      final bool success = response['success'] == true;
      
      if (success) {
        await loadCart();
      } else {
        _error = response['error'] ?? 'Failed to update cart';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    // ✅ FIXED: Proper boolean check with await
    final bool isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn == false) {
      _error = 'Please login to remove items from cart';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.removeFromCart(productId);
      
      print('🗑️ Remove from cart response: $response');
      
      // ✅ FIXED: Proper boolean check
      final bool success = response['success'] == true;
      
      if (success) {
        await loadCart();
      } else {
        _error = response['error'] ?? 'Failed to remove item from cart';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    // ✅ FIXED: Proper boolean check with await
    final bool isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn == false) {
      _error = 'Please login to clear cart';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.clearCart();
      
      print('🧹 Clear cart response: $response');
      
      // ✅ FIXED: Proper boolean check
      final bool success = response['success'] == true;
      
      if (success) {
        _items = [];
        _cartTotal = 0.0;
        _isLoading = false;
        notifyListeners();
      } else {
        _error = response['error'] ?? 'Failed to clear cart';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkout({
    required String shippingAddress,
    required String paymentMethod,
    String city = '',
    String zipCode = '',
  }) async {
    // ✅ FIXED: Proper boolean check with await
    final bool isLoggedIn = await ApiService.isLoggedIn();
    if (isLoggedIn == false) {
      _error = 'Please login to checkout';
      notifyListeners();
      return;
    }

    if (_items.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createOrder(
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        city: city,
        zipCode: zipCode,
        totalAmount: _cartTotal,
      );
      
      print('💰 Checkout response: $response');
      
      // ✅ FIXED: Proper boolean check
      final bool success = response['success'] == true;
      
      if (success) {
        _items = [];
        _cartTotal = 0.0;
        _error = null;
        _isLoading = false;
        notifyListeners();
        
        print('🎉 Order created successfully!');
      } else {
        _error = response['error'] ?? 'Failed to create order';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isLoading = false;
      notifyListeners();
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

  // Get cart summary for quick display
  Map<String, dynamic> get cartSummary {
    return {
      'itemCount': itemCount,
      'totalPrice': totalPrice,
      'items': _items.map((item) => item.toString()).toList(),
    };
  }

  // Quick add method for products
  Future<void> quickAddToCart(String productId) async {
    await addToCart(productId, 1);
  }

  // Increment quantity
  Future<void> incrementQuantity(String productId) async {
    final currentQuantity = getQuantity(productId);
    await updateQuantity(productId, currentQuantity + 1);
  }

  // Decrement quantity
  Future<void> decrementQuantity(String productId) async {
    final currentQuantity = getQuantity(productId);
    if (currentQuantity > 1) {
      await updateQuantity(productId, currentQuantity - 1);
    } else {
      await removeFromCart(productId);
    }
  }
}