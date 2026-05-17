import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'app.dart';
import 'services/promo_repository.dart';

void main() async {
  // Asegurar que la UI esté inicializada
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  if (!EnvConfig.isConfigured) {
    throw Exception(
      'Configuración incompleta: copiá .env.example a .env y completá SUPABASE_URL y SUPABASE_ANON_KEY.',
    );
  }

  final configWarning = EnvConfig.configurationWarning;
  if (configWarning != null) {
    debugPrint('⚠️ Supabase: $configWarning');
  }

  // Inicializar Supabase con las credenciales del .env
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  await PromoRepository().ensureInitialized();

  // Forzar orientación portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const AfterBurgersEvoApp());
}