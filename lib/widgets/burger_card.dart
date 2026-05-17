import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/burger.dart';
import '../utils/price_formatter.dart';
import 'product_image.dart';

class BurgerCard extends StatelessWidget {
  final Burger burger;
  final bool isFavorita;
  final VoidCallback? onTap;
  final VoidCallback? onCustomize;
  final VoidCallback? onGroupOrder;

  const BurgerCard({
    super.key,
    required this.burger,
    this.isFavorita = false,
    this.onTap,
    this.onCustomize,
    this.onGroupOrder,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppConstants.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isFavorita ? accent.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: isFavorita ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: ProductImage(
                      imagePath: burger.imagePath,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          burger.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          PriceFormatter.formatFromString(burger.precio),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      AppConstants.includesFries,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      burger.descripcion,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildMainButton(accent),
                    const SizedBox(height: 12),
                    _buildExtraButtons(accent),
                  ],
                ),
              )
            ],
          ),
          if (isFavorita)
            Positioned(
              top: 30,
              right: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TU FAVORITA ⭐',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainButton(Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          gradient: LinearGradient(
            colors: [
              accent,
              Colors.white.withOpacity(0.7),
              accent,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'AGREGAR AL CARRITO',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraButtons(Color accent) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onGroupOrder,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              'PARA VARIOS',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onCustomize,
          icon: Icon(Icons.tune, color: accent, size: 28),
        ),
      ],
    );
  }
}