import 'product.dart';

class SaleItem {
  final Product product;
  double quantity;

  SaleItem({
    required this.product,
    required this.quantity,
  });

  /// Total por producto (calculado siempre)
  double get total => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      // ❌ NO guardes total (se calcula)
    };
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        product: Product.fromJson(
          json['product'] as Map<String, dynamic>,
          json['product']['id'] ?? '',
        ),
        quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      );
}