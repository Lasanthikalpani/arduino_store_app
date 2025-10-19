// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
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

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getCart();
      
      if (response['success'] == true) {
        final cartData = response['cart'];
        if (cartData['items'] != null) {
          final itemsData = cartData['items'] as List;
          _items = itemsData.map((itemJson) {
            return CartItem.fromJson(itemJson);
          }).toList();
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