import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/burger.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_image.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final SupabaseService _supabaseService = SupabaseService();
  final StorageService _storageService = StorageService();
  List<Burger> _productos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final productos = await _supabaseService.getProductos();
      setState(() {
        _productos = productos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarProducto(Burger burger) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.darkSurface,
        title: const Text('¿Eliminar producto?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${burger.nombre}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Si la imagen es de Supabase, eliminarla del storage
        if (burger.imagePath.startsWith('http') && 
            burger.imagePath.contains('supabase')) {
          await _storageService.deleteImageFromStorage(burger.imagePath);
        }
        
        await _supabaseService.deleteProducto(burger.id);
        await _cargarProductos();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error eliminando producto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _abrirEditorProducto([Burger? burger]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditor(
          burger: burger,
          onSuccess: _cargarProductos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('ADMINISTRAR PRODUCTOS',
            style: GoogleFonts.bebasNeue(letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, 
                          size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text('Error: $_error',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarProductos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('REINTENTAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : _productos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu,
                              size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text('NO HAY PRODUCTOS',
                              style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'Comienza agregando tu primer producto',
                              style: TextStyle(color: Colors.white24)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _abrirEditorProducto(),
                            icon: const Icon(Icons.add),
                            label: const Text('AGREGAR PRODUCTO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              minimumSize: const Size(200, 50),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarProductos,
                      color: AppConstants.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _productos.length,
                        itemBuilder: (context, index) {
                          final burger = _productos[index];
                          return _buildProductoCard(burger);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEditorProducto(),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductoCard(Burger burger) {
    return Card(
      color: AppConstants.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _abrirEditorProducto(burger),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(
                  imagePath: burger.imagePath,
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      burger.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${burger.precio}',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      burger.categoria,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Botones de acción
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: AppConstants.primaryColor,
                    onPressed: () => _abrirEditorProducto(burger),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.redAccent,
                    onPressed: () => _eliminarProducto(burger),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// EDITOR DE PRODUCTOS (CREAR/EDITAR)
// ==========================================================
class ProductEditor extends StatefulWidget {
  final Burger? burger;
  final VoidCallback? onSuccess;

  const ProductEditor({
    super.key,
    this.burger,
    this.onSuccess,
  });

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _ingredienteNuevoController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _storageService = StorageService();

  String _categoriaSeleccionada = 'burgers';
  List<String> _ingredientesSeleccionados = [];
  String? _imagenUrl;
  bool _guardando = false;

  final List<String> _categoriasBase = [
    'burgers',
    'bebidas',
    'postres',
    'papas',
    'combos',
  ];

  final List<String> _ingredientesBase = [
    'Carne',
    'Pan',
    'Lechuga',
    'Tomate',
    'Cebolla',
    'Queso',
    'Panceta',
    'Huevo',
    'Salsa de la casa',
    'Mostaza',
    'Ketchup',
    'Mayonesa',
    'Pickles',
    'Jalapeños',
    'Barbacoa',
  ];

  late List<String> _categorias;
  late List<String> _ingredientesDisponibles;

  bool get _esEdicion => widget.burger != null;

  @override
  void initState() {
    super.initState();
    _categorias = List<String>.from(_categoriasBase);
    _ingredientesDisponibles = List<String>.from(_ingredientesBase);
    if (_esEdicion) {
      _nombreController.text = widget.burger!.nombre;
      _precioController.text = widget.burger!.precio;
      _descripcionController.text = widget.burger!.descripcion;
      _categoriaSeleccionada = widget.burger!.categoria;
      _ingredientesSeleccionados = List.from(widget.burger!.ingredientes);
      _imagenUrl = widget.burger!.imagePath;
    }

    // Asegurar que lo cargado/ingresado también aparezca en las listas
    // (por ejemplo, categorías/ingredientes custom).
    if (_categoriaSeleccionada.trim().isNotEmpty &&
        !_categorias.contains(_categoriaSeleccionada.trim().toLowerCase())) {
      _categorias.add(_categoriaSeleccionada.trim().toLowerCase());
    }
    for (final ing in _ingredientesSeleccionados) {
      if (!_ingredientesDisponibles.contains(ing)) {
        _ingredientesDisponibles.add(ing);
      }
    }
    _categoriaController.text = _categoriaSeleccionada;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    _categoriaController.dispose();
    _ingredienteNuevoController.dispose();
    super.dispose();
  }

  String _normalizarIngrediente(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    // Mantener un estilo consistente: "Tomate", "Salsa de la casa", etc.
    return t.length == 1 ? t.toUpperCase() : '${t[0].toUpperCase()}${t.substring(1)}';
  }

  bool _contieneIngrediente(List<String> lista, String ingrediente) {
    final objetivo = ingrediente.trim().toLowerCase();
    return lista.any((e) => e.trim().toLowerCase() == objetivo);
  }

  void _agregarIngredientePorTeclado(String raw) {
    final ing = _normalizarIngrediente(raw);
    if (ing.isEmpty) return;

    setState(() {
      if (!_contieneIngrediente(_ingredientesSeleccionados, ing)) {
        _ingredientesSeleccionados.add(ing);
      }
      if (!_contieneIngrediente(_ingredientesDisponibles, ing)) {
        _ingredientesDisponibles.add(ing);
      }
      _ingredienteNuevoController.clear();
    });
  }

  Future<void> _seleccionarImagen() async {
    final action = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.darkSurface,
        title: const Text('Seleccionar imagen',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Galería', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Cámara', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 2),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    try {
      final image = action == 1
          ? await _storageService.pickImageFromGallery()
          : await _storageService.takePhoto();

      if (image != null && mounted) {
        setState(() => _guardando = true);
        
        // Subir imagen a Supabase Storage
        final imageUrl = await _storageService.uploadImageToStorage(image);
        
        setState(() {
          _imagenUrl = imageUrl;
          _guardando = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen subida correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error subiendo imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagenUrl == null || _imagenUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una imagen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      // Normalizar categoría desde el input (si se escribió a mano)
      final cat = _categoriaController.text.trim().toLowerCase();
      _categoriaSeleccionada = cat.isEmpty ? 'burgers' : cat;
      if (!_categorias.contains(_categoriaSeleccionada)) {
        _categorias.add(_categoriaSeleccionada);
      }

      final burger = Burger(
        id: widget.burger?.id ?? const Uuid().v4(),
        nombre: _nombreController.text.trim(),
        precio: _precioController.text.trim(),
        imagePath: _imagenUrl!,
        descripcion: _descripcionController.text.trim(),
        ingredientes: _ingredientesSeleccionados,
        categoria: _categoriaSeleccionada,
      );

      if (_esEdicion) {
        await _supabaseService.updateProducto(burger);
      } else {
        await _supabaseService.createProducto(burger);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion
                ? 'Producto actualizado correctamente'
                : 'Producto creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppConstants.primaryColor;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'EDITAR PRODUCTO' : 'NUEVO PRODUCTO',
          style: GoogleFonts.bebasNeue(letterSpacing: 2),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _guardando
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Selector de imagen
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: _imagenUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: ProductImage(
                                imagePath: _imagenUrl!,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 64, color: Colors.white24),
                                const SizedBox(height: 8),
                                const Text(
                                  'Toca para agregar imagen',
                                  style: TextStyle(color: Colors.white24),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant, color: Colors.white38),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  TextFormField(
                    controller: _precioController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio (\$)',
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money, color: Colors.white38),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa un precio';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Ingresa un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description, color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categoría
                  const Text('Categoría',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _categoriaController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Escribí o elegí una categoría',
                      labelStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, color: Colors.white38),
                    ),
                    onChanged: (v) => setState(() => _categoriaSeleccionada = v.trim()),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _categorias.map((categoria) {
                      final isSelected = _categoriaSeleccionada == categoria;
                      return ChoiceChip(
                        label: Text(categoria.toUpperCase()),
                        selected: isSelected,
                        selectedColor: accent,
                        backgroundColor: Colors.white10,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() => _categoriaSeleccionada = categoria);
                          _categoriaController.text = categoria;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Ingredientes
                  const Text('Ingredientes',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ingredienteNuevoController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Agregar ingrediente por teclado',
                            labelStyle: TextStyle(color: Colors.white38),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.add, color: Colors.white38),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: _agregarIngredientePorTeclado,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _agregarIngredientePorTeclado(
                            _ingredienteNuevoController.text,
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: accent),
                          child: const Icon(Icons.check, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ingredientesSeleccionados.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ingredientesSeleccionados.map((ing) {
                        return InputChip(
                          label: Text(ing),
                          backgroundColor: Colors.white10,
                          labelStyle: const TextStyle(color: Colors.white70),
                          deleteIconColor: Colors.redAccent,
                          onDeleted: () => setState(() {
                            _ingredientesSeleccionados.removeWhere(
                              (e) => e.trim().toLowerCase() == ing.trim().toLowerCase(),
                            );
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ingredientesDisponibles.map((ingrediente) {
                      final isSelected = _ingredientesSeleccionados.contains(ingrediente);
                      return FilterChip(
                        label: Text(ingrediente),
                        selected: isSelected,
                        selectedColor: accent.withOpacity(0.3),
                        checkmarkColor: accent,
                        backgroundColor: Colors.white10,
                        labelStyle: TextStyle(
                          color: isSelected ? accent : Colors.white70,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!_contieneIngrediente(
                                _ingredientesSeleccionados,
                                ingrediente,
                              )) {
                                _ingredientesSeleccionados.add(ingrediente);
                              }
                            } else {
                              _ingredientesSeleccionados.removeWhere(
                                (e) =>
                                    e.trim().toLowerCase() ==
                                    ingrediente.trim().toLowerCase(),
                              );
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Botón guardar
                  ElevatedButton(
                    onPressed: _guardarProducto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      _esEdicion ? 'ACTUALIZAR PRODUCTO' : 'CREAR PRODUCTO',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
