class Promo {
  final String id;
  final String titulo;
  final String descripcion;
  final String tipo;
  final String etiqueta;
  final bool activa;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? _productoObjetivo;
  final int _descuentoPorcentaje;

  const Promo({
    this.id = '',
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    this.etiqueta = '',
    this.activa = true,
    required this.fechaInicio,
    required this.fechaFin,
    String? productoObjetivo,
    int descuentoPorcentaje = 0,
  })  : _productoObjetivo = productoObjetivo,
        _descuentoPorcentaje = descuentoPorcentaje;

  /// Burger objetivo para 2x1 (ej: CLÁSICA). Se infiere del título si falta.
  String? get productoObjetivo {
    if (_productoObjetivo != null && _productoObjetivo.isNotEmpty) {
      return _productoObjetivo;
    }
    if (tipo == '2x1') {
      final match = RegExp(r'en\s+(.+)$', caseSensitive: false).firstMatch(titulo);
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }

  int get descuentoPorcentaje => _descuentoPorcentaje;

  static const Map<String, String> tiposLabels = {
    'regalo': 'Regalo con compra',
    '2x1': '2x1',
    'descuento': 'Descuento',
    'combo': 'Combo especial',
    'otro': 'Otra promo',
  };

  static const Map<String, String> tiposEmojis = {
    'regalo': '🎁',
    '2x1': '🔥',
    'descuento': '💰',
    'combo': '🍔',
    'otro': '⭐',
  };

  String get emoji => tiposEmojis[tipo] ?? '🎉';
  String get tipoLabel => tiposLabels[tipo] ?? tipo;

  bool get estaVigente {
    if (!activa) return false;
    final now = DateTime.now();
    return !now.isBefore(fechaInicio) && !now.isAfter(fechaFin);
  }

  String get vigenciaTexto {
    final inicio = _formatFecha(fechaInicio);
    final fin = _formatFecha(fechaFin);
    return '$inicio → $fin';
  }

  String _formatFecha(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static const String promoMarker = 'promo_row:true';

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'otro',
      etiqueta: json['etiqueta']?.toString() ?? '',
      activa: json['activa'] as bool? ?? true,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String).toLocal(),
      fechaFin: DateTime.parse(json['fecha_fin'] as String).toLocal(),
      productoObjetivo: json['producto_objetivo']?.toString(),
      descuentoPorcentaje: json['descuento_porcentaje'] as int? ?? 0,
    );
  }

  /// Lee una promo guardada en la tabla `productos`.
  factory Promo.fromProductoRow(Map<String, dynamic> json) {
    var tipo = 'otro';
    var activa = true;
    var inicio = DateTime.now();
    var fin = DateTime.now().add(const Duration(days: 7));
    var etiqueta = json['image_path']?.toString() ?? '';
    String? productoObjetivo;
    var descuentoPorcentaje = 0;

    for (final raw in List<String>.from(json['ingredientes'] ?? [])) {
      if (raw.startsWith('promo_tipo:')) tipo = raw.substring(11);
      if (raw.startsWith('promo_activa:')) activa = raw.substring(13) == 'true';
      if (raw.startsWith('promo_inicio:')) {
        inicio = DateTime.parse(raw.substring(13)).toLocal();
      }
      if (raw.startsWith('promo_fin:')) {
        fin = DateTime.parse(raw.substring(9)).toLocal();
      }
      if (raw.startsWith('promo_etiqueta:')) etiqueta = raw.substring(15);
      if (raw.startsWith('promo_producto:')) {
        productoObjetivo = raw.substring(15);
      }
      if (raw.startsWith('promo_descuento:')) {
        descuentoPorcentaje = int.tryParse(raw.substring(16)) ?? 0;
      }
    }

    return Promo(
      id: json['id']?.toString() ?? '',
      titulo: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      tipo: tipo,
      etiqueta: etiqueta,
      activa: activa,
      fechaInicio: inicio,
      fechaFin: fin,
      productoObjetivo: productoObjetivo,
      descuentoPorcentaje: descuentoPorcentaje,
    );
  }

  static bool esFilaPromo(List<String> ingredientes) =>
      ingredientes.contains(promoMarker);

  List<String> get _metadataIngredientes => [
        promoMarker,
        'promo_tipo:$tipo',
        'promo_activa:$activa',
        'promo_inicio:${fechaInicio.toUtc().toIso8601String()}',
        'promo_fin:${fechaFin.toUtc().toIso8601String()}',
        if (etiqueta.isNotEmpty) 'promo_etiqueta:$etiqueta',
        if (_productoObjetivo != null && _productoObjetivo.isNotEmpty)
          'promo_producto:$_productoObjetivo',
        if (_descuentoPorcentaje > 0) 'promo_descuento:$_descuentoPorcentaje',
      ];

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'etiqueta': etiqueta,
      'activa': activa,
      'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
      'fecha_fin': fechaFin.toUtc().toIso8601String(),
      if (productoObjetivo != null && productoObjetivo!.isNotEmpty)
        'producto_objetivo': productoObjetivo,
      if (descuentoPorcentaje > 0) 'descuento_porcentaje': descuentoPorcentaje,
    };
  }

  Map<String, dynamic> toProductoRow({bool includeId = true}) {
    final row = <String, dynamic>{
      'nombre': titulo,
      'descripcion': descripcion,
      'precio': 0,
      'image_path': etiqueta.isNotEmpty ? etiqueta : emoji,
      'ingredientes': _metadataIngredientes,
    };
    final numericId = int.tryParse(id);
    if (includeId && numericId != null) {
      row['id'] = numericId;
    }
    return row;
  }

  Promo copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? tipo,
    String? etiqueta,
    bool? activa,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? productoObjetivo,
    int? descuentoPorcentaje,
  }) {
    return Promo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      etiqueta: etiqueta ?? this.etiqueta,
      activa: activa ?? this.activa,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      productoObjetivo: productoObjetivo ?? _productoObjetivo,
      descuentoPorcentaje: descuentoPorcentaje ?? _descuentoPorcentaje,
    );
  }
}
