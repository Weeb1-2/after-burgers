import 'package:burguer_app/models/burger.dart';
import 'package:burguer_app/models/cart_item.dart';
import 'package:burguer_app/models/promo.dart';
import 'package:burguer_app/services/promo_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clasica = Burger(
    nombre: 'CLÁSICA',
    descripcion: 'Test',
    precio: '10000',
    imagePath: 'assets/images/clasica.jpg',
    ingredientes: const ['carne'],
  );

  final now = DateTime.now();
  final fin = now.add(const Duration(days: 7));

  test('2x1 aplica descuento por unidades pares', () {
    final promo = Promo(
      titulo: '2x1 en Clásica',
      descripcion: 'Dos al precio de una',
      tipo: '2x1',
      productoObjetivo: 'CLÁSICA',
      fechaInicio: now,
      fechaFin: fin,
    );

    final items = [
      CartItem(burger: clasica, personas: 2),
    ];

    final totals = PromoCalculator.calculate(items, [promo]);

    expect(totals.subtotal, 20000);
    expect(totals.discount, 10000);
    expect(totals.total, 10000);
    expect(totals.discountLines, isNotEmpty);
  });

  test('descuento porcentual reduce el subtotal', () {
    final promo = Promo(
      titulo: '10% off',
      descripcion: 'Descuento general',
      tipo: 'descuento',
      descuentoPorcentaje: 10,
      fechaInicio: now,
      fechaFin: fin,
    );

    final items = [CartItem(burger: clasica, personas: 1)];
    final totals = PromoCalculator.calculate(items, [promo]);

    expect(totals.subtotal, 10000);
    expect(totals.discount, 1000);
    expect(totals.total, 9000);
  });

  test('promo regalo agrega nota sin descontar', () {
    final promo = Promo(
      titulo: 'Papas gratis',
      descripcion: 'Con cualquier burger',
      tipo: 'regalo',
      fechaInicio: now,
      fechaFin: fin,
    );

    final items = [CartItem(burger: clasica, personas: 1)];
    final totals = PromoCalculator.calculate(items, [promo]);

    expect(totals.discount, 0);
    expect(totals.total, 10000);
    expect(totals.promoNotes, isNotEmpty);
  });
}
