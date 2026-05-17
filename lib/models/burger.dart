class Burger {
  final String id;
  final String nombre;
  final String precio;
  final String imagePath;
  final String descripcion;
  final List<String> ingredientes;
  final String categoria;
  final DateTime? createdAt;
  final int? orden;

  Burger({
    this.id = '',
    required this.nombre,
    required this.precio,
    required this.imagePath,
    required this.descripcion,
    required this.ingredientes,
    this.categoria = 'burgers',
    this.createdAt,
    this.orden,
  });

  // Factory para crear desde JSON (Supabase)
  factory Burger.fromJson(Map<String, dynamic> json) {
    final rawIngredientes = json['ingredientes'];
    final ingredientes = rawIngredientes is List
        ? rawIngredientes.map((e) => e.toString()).toList()
        : <String>[];

    final rawOrden = json['orden'];
    final orden = rawOrden is int
        ? rawOrden
        : int.tryParse(rawOrden?.toString() ?? '');

    return Burger(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      precio: (json['precio'] ?? json['price'] ?? 0).toString(),
      imagePath: (json['image_path'] ?? json['imagePath'] ?? '').toString(),
      descripcion: json['descripcion']?.toString() ?? '',
      ingredientes: ingredientes,
      categoria: json['categoria'] ?? 'burgers',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      orden: orden,
    );
  }

  // Convertir a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'precio': int.tryParse(precio) ?? 0,
      'image_path': imagePath,
      'descripcion': descripcion,
      'ingredientes': ingredientes,
      'categoria': categoria,
      if (orden != null) 'orden': orden,
    };
  }

  // Copy with para actualizaciones
  Burger copyWith({
    String? id,
    String? nombre,
    String? precio,
    String? imagePath,
    String? descripcion,
    List<String>? ingredientes,
    String? categoria,
    int? orden,
  }) {
    return Burger(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      imagePath: imagePath ?? this.imagePath,
      descripcion: descripcion ?? this.descripcion,
      ingredientes: ingredientes ?? this.ingredientes,
      categoria: categoria ?? this.categoria,
      orden: orden ?? this.orden,
    );
  }
}
