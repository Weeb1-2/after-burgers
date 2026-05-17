import '../models/cart_item.dart';
import '../models/promo.dart';
import '../utils/price_formatter.dart';

class CartTotals {
  final int subtotal;
  final int discount;
  final List<String> discountLines;
  final List<String> promoNotes;

  const CartTotals({
    required this.subtotal,
    this.discount = 0,
    this.discountLines = const [],
    this.promoNotes = const [],
  });

  int get total => (subtotal - discount).clamp(0, subtotal);
}

class PromoCalculator {
  static CartTotals calculate(List<CartItem> items, List<Promo> promos) {
    final subtotal = items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    var discount = 0;
    final discountLines = <String>[];
    final promoNotes = <String>[];

    for (final promo in promos) {
      if (!promo.estaVigente) continue;

      switch (promo.tipo) {
        case '2x1':
          final target = promo.productoObjetivo;
          if (target == null) continue;
          for (final item in items) {
            if (!_matchesProduct(item.burger.nombre, target)) continue;
            final unitPrice =
                (int.tryParse(item.burger.precio) ?? 0) + item.extraPrecio;
            final freeUnits = item.personas ~/ 2;
            final lineDiscount = freeUnits * unitPrice;
            if (lineDiscount > 0) {
              discount += lineDiscount;
              discountLines.add(
                '${promo.etiqueta.isNotEmpty ? promo.etiqueta : promo.titulo}: '
                '-${PriceFormatter.format(lineDiscount)}',
              );
            }
          }
        case 'descuento':
          if (promo.descuentoPorcentaje > 0) {
            final lineDiscount =
                (subtotal * promo.descuentoPorcentaje / 100).round();
            if (lineDiscount > 0) {
              discount += lineDiscount;
              discountLines.add(
                '${promo.titulo}: -${PriceFormatter.format(lineDiscount)} '
                '(${promo.descuentoPorcentaje}%)',
              );
            }
          }
        case 'regalo':
        case 'combo':
        case 'otro':
          promoNotes.add('${promo.emoji} ${promo.titulo}: ${promo.descripcion}');
      }
    }

    return CartTotals(
      subtotal: subtotal,
      discount: discount.clamp(0, subtotal),
      discountLines: discountLines,
      promoNotes: promoNotes,
    );
  }

  static bool _matchesProduct(String burgerName, String target) {
    final a = _normalize(burgerName);
    final b = _normalize(target);
    return a.contains(b) || b.contains(a);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .trim();
  }
}
