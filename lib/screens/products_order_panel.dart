import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../models/burger.dart';
import '../services/supabase_service.dart';
import '../widgets/product_image.dart';

class ProductsOrderPanel extends StatefulWidget {
  final List<Burger> productos;
  final VoidCallback? onSaved;

  const ProductsOrderPanel({super.key, required this.productos, this.onSaved});

  @override
  State<ProductsOrderPanel> createState() => _ProductsOrderPanelState();
}

class _ProductsOrderPanelState extends State<ProductsOrderPanel> {
  final _supabase = SupabaseService();
  late List<Burger> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List<Burger>.from(widget.productos);
    _items.sort((a, b) {
      final ao = a.orden ?? 1 << 30;
      final bo = b.orden ?? 1 << 30;
      final cmp = ao.compareTo(bo);
      if (cmp != 0) return cmp;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  }

  Future<void> _guardarOrden() async {
    setState(() => _saving = true);
    try {
      await _supabase.updateOrdenProductos(_items);
      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden guardado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $msg'),
          backgroundColor: Colors.red,
        ),
      );

      // Tip extra si falta la columna.
      if (msg.toLowerCase().contains('orden') &&
          (msg.toLowerCase().contains('does not exist') ||
              msg.toLowerCase().contains('column') ||
              msg.toLowerCase().contains('schema cache'))) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppConstants.darkSurface,
            title: const Text(
              'Falta la columna "orden"',
              style: TextStyle(color: Colors.white),
            ),
            content: const SelectableText(
              'Creala en Supabase (SQL editor):\n\n'
              'alter table public.productos add column if not exists orden integer;\n'
              'create index if not exists productos_orden_idx on public.productos (orden);\n',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'ORDENAR MENÚ',
          style: GoogleFonts.bebasNeue(letterSpacing: 2),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _saving ? null : _guardarOrden,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: _saving
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _items.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final b = _items[index];
                return Card(
                  key: ValueKey(b.id.isNotEmpty ? b.id : '${b.nombre}-$index'),
                  color: AppConstants.cardColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ProductImage(
                        imagePath: b.imagePath,
                        width: 46,
                        height: 46,
                      ),
                    ),
                    title: Text(
                      '${index + 1}. ${b.nombre}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      b.categoria,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
