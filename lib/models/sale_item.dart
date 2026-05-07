import 'product.dart';

class SaleItem {
  final Product product;
  double quantity;

  SaleItem({
    required this.product,
    required this.quantity, required total,
  });

  /// Total por producto
  double get total => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(), // 🟢 Vital: Esto guarda toda la fruta/producto
      'quantity': quantity,
      'total': total,              // 🟢 El campo que agregamos hoy
    };
  }

 factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      // 🟢 CONVERSIÓN SEGURA: Lee el dato sin importar si Firebase lo mandó como texto, entero o nulo.
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
    );
}

