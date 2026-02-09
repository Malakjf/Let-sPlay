import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Repository for managing products in Firestore
class ProductRepository {
  ProductRepository._internal();
  static final ProductRepository instance = ProductRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'products';

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      debugPrint('📦 Loading all products');
      final snapshot = await _db
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc.data(), doc.id))
          .toList();

      debugPrint('✅ Loaded ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  Future<Product?> getProduct(String productId) async {
    try {
      debugPrint('📦 Loading product: $productId');
      final doc = await _db.collection(_collectionName).doc(productId).get();

      if (!doc.exists) {
        debugPrint('⚠️ Product not found');
        return null;
      }

      final product = Product.fromFirestore(doc.data()!, doc.id);
      debugPrint('✅ Product loaded');
      return product;
    } catch (e) {
      debugPrint('❌ Error loading product: $e');
      rethrow;
    }
  }

  /// Create a new product
  Future<String> createProduct(Product product) async {
    try {
      debugPrint('📦 Creating product: ${product.name}');
      final docRef = await _db
          .collection(_collectionName)
          .add(product.toFirestore());

      debugPrint('✅ Product created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating product: $e');
      rethrow;
    }
  }

  /// Update an existing product
  Future<void> updateProduct(Product product) async {
    try {
      debugPrint('📦 Updating product: ${product.id}');
      await _db
          .collection(_collectionName)
          .doc(product.id)
          .update(product.toFirestore());

      debugPrint('✅ Product updated');
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      debugPrint('📦 Deleting product: $productId');
      await _db.collection(_collectionName).doc(productId).delete();

      debugPrint('✅ Product deleted');
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
      rethrow;
    }
  }

  /// Update product image URL
  Future<void> updateProductImage(String productId, String imageUrl) async {
    try {
      debugPrint('📦 Updating product image: $productId');
      await _db.collection(_collectionName).doc(productId).update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Product image updated');
    } catch (e) {
      debugPrint('❌ Error updating product image: $e');
      rethrow;
    }
  }

  /// Get products stream for real-time updates
  Stream<List<Product>> getProductsStream() {
    return _db
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
