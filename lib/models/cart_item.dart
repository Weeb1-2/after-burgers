import 'burger.dart';

class CartItem {
  final Burger burger;
  final int personas;
  final List<String> ingredientesQuitados;
  final List<String> adicionalesSumados;
  final int extraPrecio;

  CartItem({
    required this.burger,
    this.personas = 1,
    this.ingredientesQuitados = const [],
    this.adicionalesSumados = const [],
    this.extraPrecio = 0,
  });

  // Precio total del item (precio base + extras) * cantidad
  int get totalPrice {
    final basePrice = int.tryParse(burger.precio) ?? 0;
    return (basePrice + extraPrecio) * personas;
  }

  // Descripción resumida del item
  String get resumen {
    List<String> partes = [];
    
    if (personas > 1) {
      partes.add('Para $personas personas');
    }
    
    if (ingredientesQuitados.isNotEmpty) {
      partes.add('Sin: ${ingredientesQuitados.join(', ')}');
    }
    
    if (adicionalesSumados.isNotEmpty) {
      partes.add('Extra: ${adicionalesSumados.join(', ')}');
    }
    
    if (partes.isEmpty) {
      return 'Completa';
    }
    
    return partes.join(' | ');
  }

  // Copy with para actualizaciones
  CartItem copyWith({
    Burger? burger,
    int? personas,
    List<String>? ingredientesQuitados,
    List<String>? adicionalesSumados,
    int? extraPrecio,
  }) {
    return CartItem(
      burger: burger ?? this.burger,
      personas: personas ?? this.personas,
      ingredientesQuitados: ingredientesQuitados ?? this.ingredientesQuitados,
      adicionalesSumados: adicionalesSumados ?? this.adicionalesSumados,
      extraPrecio: extraPrecio ?? this.extraPrecio,
    );
  }
}