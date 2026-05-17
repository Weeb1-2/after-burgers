import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/env.dart';

/// Muestra la imagen de un producto según cómo esté guardada en Supabase:
/// - `assets/...` → asset local del proyecto
/// - `http...` → URL remota
/// - cualquier otra ruta → archivo en Supabase Storage (bucket público)
class ProductImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? accentColor;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.accentColor,
  });

  static String resolveUri(String imagePath) {
    if (imagePath.isEmpty) return imagePath;
    if (imagePath.startsWith('http') || imagePath.startsWith('assets/')) {
      return imagePath;
    }
    return EnvConfig.getImageUrl(imagePath);
  }

  static bool isLocalAsset(String imagePath) => imagePath.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _placeholder();
    }

    if (isLocalAsset(imagePath)) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final uri = resolveUri(imagePath);
    final accent = accentColor ?? AppConstants.primaryColor;

    return CachedNetworkImage(
      imageUrl: uri,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => Container(
        color: Colors.white10,
        width: width,
        height: height,
        child: Center(
          child: CircularProgressIndicator(
            color: accent,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white10,
      width: width,
      height: height,
      child: const Icon(Icons.fastfood, size: 50, color: Colors.white24),
    );
  }
}
