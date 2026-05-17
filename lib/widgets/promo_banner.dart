import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../models/promo.dart';

class PromoBannerCarousel extends StatelessWidget {
  final List<Promo> promos;

  const PromoBannerCarousel({super.key, required this.promos});

  @override
  Widget build(BuildContext context) {
    if (promos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: promos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _PromoCard(promo: promos[index]),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Promo promo;

  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    const accent = AppConstants.primaryColor;
    final badge = promo.etiqueta.isNotEmpty ? promo.etiqueta : promo.tipoLabel;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.18),
            AppConstants.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(promo.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 11,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.local_offer, color: accent, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promo.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              promo.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
