class Product {
  String id;
  String name;
  double price;
  double stock;
  bool isByWeight;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.isByWeight = false,
  });

  // 🟢 AGREGADO: Método para clonar el producto en memoria de forma independiente
  Product copy() {
    return Product(
      id: id,
      name: name,
      price: price,
      stock: stock,
      isByWeight: isByWeight,
    );
  }

  /// Convertir objeto a JSON (para guardar)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock, // Opcional, si no usas stock puedes quitar esta línea
      'isByWeight': isByWeight,
    };
  }

  /// Convertir JSON a objeto
  factory Product.fromJson(Map<String, dynamic> json, String docId) => Product(
  id: docId, // 🔥 ID REAL DE FIREBASE
  name: json['name']?.toString() ?? 'Sin nombre',
  price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
  stock: double.tryParse(json['stock']?.toString() ?? '0') ?? 0.0,
  isByWeight: json['isByWeight'] ?? false,
);
}