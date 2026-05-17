// Sincroniza promos en Supabase (metadata 2x1) y verifica tabla promociones.
// Ejecutar: dart run tool/sync_supabase.dart
// Requiere .env con SUPABASE_URL y SUPABASE_ANON_KEY.

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final env = _loadEnv(File('.env'));
  final url = env['SUPABASE_URL'];
  final key = env['SUPABASE_ANON_KEY'] ?? env['SUPABASE_PUBLISHABLE_KEY'];
  if (url == null || key == null) {
    stderr.writeln('Falta SUPABASE_URL o SUPABASE_ANON_KEY en .env');
    exit(1);
  }

  final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  final headers = {
    'apikey': key,
    'Authorization': 'Bearer $key',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  stdout.writeln('Comprobando tabla promociones...');
  final promosCheck = await _request('GET', '$base/rest/v1/promociones?select=id&limit=1', headers);
  if (promosCheck.status == 200) {
    stdout.writeln('✓ Tabla promociones existe. La app la usará automáticamente.');
  } else {
    stdout.writeln(
      '⚠ Tabla promociones no disponible (${promosCheck.status}). '
      'Ejecutá supabase/setup_completo.sql en el SQL Editor de Supabase.',
    );
  }

  stdout.writeln('Actualizando filas promo en productos...');
  final productosRes = await _request(
    'GET',
    '$base/rest/v1/productos?select=id,nombre,ingredientes',
    headers,
  );
  if (productosRes.status != 200) {
    stderr.writeln('Error leyendo productos: ${productosRes.body}');
    exit(1);
  }

  final productos = jsonDecode(productosRes.body!) as List;
  var updated = 0;

  for (final row in productos) {
    final map = row as Map<String, dynamic>;
    final ingredientes = List<String>.from(map['ingredientes'] ?? []);
    if (!ingredientes.contains('promo_row:true')) continue;

    final nombre = (map['nombre'] as String?) ?? '';
    final needsProducto = ingredientes.every((i) => !i.startsWith('promo_producto:'));
    final is2x1 = ingredientes.any((i) => i == 'promo_tipo:2x1') ||
        nombre.toLowerCase().contains('2x1');

    if (!needsProducto || !is2x1) continue;

    var objetivo = 'CLÁSICA';
    final match = RegExp(r'en\s+(.+)$', caseSensitive: false).firstMatch(nombre);
    if (match != null) objetivo = match.group(1)!.trim();

    ingredientes.add('promo_producto:$objetivo');
    final patchRes = await _request(
      'PATCH',
      '$base/rest/v1/productos?id=eq.${map['id']}',
      headers,
      body: {'ingredientes': ingredientes},
    );
    if (patchRes.status >= 200 && patchRes.status < 300) {
      stdout.writeln('  → Promo id=${map['id']} ($nombre): promo_producto:$objetivo');
      updated++;
    } else {
      stderr.writeln('  ✗ id=${map['id']}: ${patchRes.status} ${patchRes.body}');
    }
  }

  stdout.writeln('Listo. Promos actualizadas en productos: $updated');

  if (promosCheck.status == 200) {
    await _migrarPromosATabla(base, headers, productos);
  }

  if (promosCheck.status != 200) {
    stdout.writeln('\nPegá y ejecutá el contenido de supabase/setup_completo.sql en:');
    stdout.writeln('https://supabase.com/dashboard/project/mhpbpxqluxnojckatktg/sql/new');
  }
}

Future<void> _migrarPromosATabla(
  String base,
  Map<String, String> headers,
  List productos,
) async {
  final existentes = await _request(
    'GET',
    '$base/rest/v1/promociones?select=titulo',
    headers,
  );
  final titulosExistentes = <String>{};
  if (existentes.status == 200 && existentes.body != null) {
    for (final row in jsonDecode(existentes.body!) as List) {
      titulosExistentes.add((row as Map)['titulo'] as String);
    }
  }

  var insertadas = 0;
  for (final row in productos) {
    final map = row as Map<String, dynamic>;
    final ingredientes = List<String>.from(map['ingredientes'] ?? []);
    if (!ingredientes.contains('promo_row:true')) continue;

    final titulo = map['nombre']?.toString() ?? '';
    if (titulosExistentes.contains(titulo)) continue;

    final meta = _parsePromoMeta(ingredientes);
    final body = {
      'titulo': titulo,
      'descripcion': map['descripcion']?.toString() ?? '',
      'tipo': meta['tipo'],
      'etiqueta': meta['etiqueta'],
      'activa': meta['activa'],
      'fecha_inicio': meta['fecha_inicio'],
      'fecha_fin': meta['fecha_fin'],
      if (meta['producto_objetivo'] != null)
        'producto_objetivo': meta['producto_objetivo'],
      'descuento_porcentaje': meta['descuento_porcentaje'],
    };

    final res = await _request(
      'POST',
      '$base/rest/v1/promociones',
      headers,
      body: body,
    );
    if (res.status >= 200 && res.status < 300) {
      stdout.writeln('  → Migrada a promociones: $titulo');
      insertadas++;
    } else {
      stderr.writeln('  ✗ Migrar $titulo: ${res.status} ${res.body}');
    }
  }
  stdout.writeln('Promos en tabla promociones: ${titulosExistentes.length + insertadas}');
}

Map<String, dynamic> _parsePromoMeta(List<String> ingredientes) {
  var tipo = 'otro';
  var activa = true;
  var etiqueta = '';
  var inicio = DateTime.now().toUtc().toIso8601String();
  var fin = DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String();
  String? productoObjetivo;
  var descuento = 0;

  for (final raw in ingredientes) {
    if (raw.startsWith('promo_tipo:')) tipo = raw.substring(11);
    if (raw.startsWith('promo_activa:')) activa = raw.substring(13) == 'true';
    if (raw.startsWith('promo_inicio:')) inicio = raw.substring(13);
    if (raw.startsWith('promo_fin:')) fin = raw.substring(9);
    if (raw.startsWith('promo_etiqueta:')) etiqueta = raw.substring(15);
    if (raw.startsWith('promo_producto:')) productoObjetivo = raw.substring(15);
    if (raw.startsWith('promo_descuento:')) {
      descuento = int.tryParse(raw.substring(16)) ?? 0;
    }
  }

  return {
    'tipo': tipo,
    'activa': activa,
    'etiqueta': etiqueta,
    'fecha_inicio': inicio,
    'fecha_fin': fin,
    'producto_objetivo': productoObjetivo,
    'descuento_porcentaje': descuento,
  };
}

Map<String, String> _loadEnv(File file) {
  if (!file.existsSync()) return {};
  final map = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final i = t.indexOf('=');
    if (i <= 0) continue;
    map[t.substring(0, i).trim()] = t.substring(i + 1).trim();
  }
  return map;
}

class _HttpResult {
  final int status;
  final String? body;
  _HttpResult(this.status, this.body);
}

Future<_HttpResult> _request(
  String method,
  String uri,
  Map<String, String> headers, {
  Map<String, dynamic>? body,
}) async {
  final client = HttpClient();
  try {
    late final HttpClientRequest req;
    final parsed = Uri.parse(uri);
    switch (method) {
      case 'PATCH':
        req = await client.patchUrl(parsed);
      case 'POST':
        req = await client.postUrl(parsed);
      case 'GET':
      default:
        req = await client.getUrl(parsed);
    }
    headers.forEach(req.headers.set);
    if (body != null) {
      final encoded = utf8.encode(jsonEncode(body));
      req.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      req.contentLength = encoded.length;
      req.add(encoded);
    }
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return _HttpResult(res.statusCode, text);
  } finally {
    client.close();
  }
}
