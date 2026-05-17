import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  /// Publishable key (sb_publishable_...) o anon legacy (eyJ...).
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      '';
  
  // Admin Configuration
  static String get adminPassword => dotenv.env['ADMIN_PASSWORD'] ?? '31647601';
  
  // WhatsApp Configuration
  static String get whatsappNumber => dotenv.env['WHATSAPP_NUMBER'] ?? '5493541612565';
  
  // Horarios
  static int get openingHour => int.tryParse(dotenv.env['OPENING_HOUR'] ?? '21') ?? 21;
  static int get closingHour => int.tryParse(dotenv.env['CLOSING_HOUR'] ?? '3') ?? 3;
  
  // Storage
  static String get storageBucket => dotenv.env['STORAGE_BUCKET'] ?? 'productos-imagenes';
  
  // Método para verificar si la configuración está completa
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;

  static bool get usesPublishableKey =>
      supabaseAnonKey.startsWith('sb_publishable_');

  static bool get usesLegacyAnonKey => supabaseAnonKey.startsWith('eyJ');

  static String? get configurationWarning {
    if (!isConfigured) {
      return 'Falta SUPABASE_URL y la publishable key en el archivo .env';
    }
    if (!usesPublishableKey && !usesLegacyAnonKey) {
      return 'La API key no parece válida. Usá la Publishable key (sb_publishable_...) o la anon legacy (eyJ...) desde Supabase → Settings → API.';
    }
    return null;
  }
  
  // URL de imagen de Supabase Storage
  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath; // Ya es una URL completa
    }
    return '$supabaseUrl/storage/v1/object/public/$storageBucket/$imagePath';
  }
}