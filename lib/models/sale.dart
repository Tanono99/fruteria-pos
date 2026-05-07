import 'package:cloud_firestore/cloud_firestore.dart';

import 'sale_item.dart';

class Sale {
  final String id;
  final List<SaleItem> items;
  final DateTime date;
  final String? customerId;
  bool isPaid;
  final double total;

  Sale({
    required this.id,
    required this.items,
    required this.date,
    this.customerId,
    required this.isPaid,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((i) => i.toJson()).toList(),
    // CAMBIO: Enviamos la fecha como Timestamp para que Firebase la entienda bien
    'date': Timestamp.fromDate(date),
    'customerId': customerId,
    'isPaid': isPaid,
    'total': total,
  };

  factory Sale.fromJson(Map<String, dynamic> json, String documentId) {
  return Sale(
    id: documentId,
    // 🛒 Si 'items' falla, devolvemos una lista vacía para que no se trabe la app
    items: (json['items'] as List?)?.map((i) {
          try {
            return SaleItem.fromJson(i as Map<String, dynamic>);
          } catch (e) {
            // Si un producto individual falla, lo ignoramos
            return null; 
          }
        }).whereType<SaleItem>().toList() ?? [],
    
    // 📅 Si la fecha no es Timestamp, intentamos leerla como texto
    date: json['date'] is Timestamp
        ? (json['date'] as Timestamp).toDate()
        : json['date'] is String
            ? DateTime.parse(json['date'])
            : DateTime.now(),
            
    customerId: json['customerId'] ?? '',
    isPaid: json['isPaid'] ?? false,
    total: (json['total'] ?? 0.0 as num).toDouble(),
  );
}
}
