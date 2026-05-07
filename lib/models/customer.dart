class Customer {
  final String id;
  String name;
  String phone;
  double balance;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'balance': balance,
      };

  factory Customer.fromJson(Map<String, dynamic> json, String documentId) => Customer(
        // Usamos documentId de Firebase si el 'id' dentro del JSON viene vacío
        id: json['id'] ?? documentId, 
        // Si el nombre es nulo, ponemos un texto por defecto para evitar crashes
        name: json['name'] ?? 'Cliente sin nombre',
        phone: json['phone'] ?? 'Sin teléfono',
        // Evitamos el error "Null is not a subtype of num"
        balance: (json['balance'] ?? 0.0 as num).toDouble(),
      );
}