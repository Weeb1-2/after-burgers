import 'package:flutter/material.dart';

class AppConstants {
  // Colores de la marca
  static const Color primaryColor = Color(0xFF00E5FF);
  static const Color backgroundColor = Colors.black;
  static const Color cardColor = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF0D0D0D);
  
  // Configuración de UI
  static const double cardBorderRadius = 40.0;
  static const double buttonBorderRadius = 18.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(20);
  
  // Duraciones de animación
  static const Duration shimmerDuration = Duration(seconds: 2);
  static const Duration badgeAnimationDuration = Duration(milliseconds: 300);
  static const Duration orderAnimationDuration = Duration(seconds: 3);
  
  // Rangos de usuario
  static String getRango(int pedidosRealizados) {
    if (pedidosRealizados < 5) return "NOVATO 🥩";
    if (pedidosRealizados < 15) return "BURGER LOVER 🍔";
    return "AFTER LEGEND 👑";
  }
  
  // Mensajes
  static const String closedMessage = "⚠️ Solo aceptamos pedidos de 21:00 a 03:00 hs.";
  static const String includesFries = "🍟 Incluye porción de papas fritas";
}