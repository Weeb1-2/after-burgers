import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/promo.dart';
import '../services/promo_repository.dart';
import '../services/supabase_service.dart';

class PromosAdminPanel extends StatefulWidget {
  const PromosAdminPanel({super.key});

  @override
  State<PromosAdminPanel> createState() => _PromosAdminPanelState();
}

class _PromosAdminPanelState extends State<PromosAdminPanel> {
  final _repo = PromoRepository();
  List<Promo> _promos = [];
  bool _cargando = true;
  bool _mostrarPausadas = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _repo.getAll();
      if (mounted) {
        setState(() {
          _promos = _mostrarPausadas ? lista : lista.where((p) => p.activa).toList();
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminar(Promo promo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkSurface,
        title: const Text(
          '¿Eliminar promo?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se eliminará "${promo.titulo}"',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final res = await _repo.delete(promo.id);
      await _cargar();
      if (!mounted) return;

      if (res == PromoDeleteResult.deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promo eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (res == PromoDeleteResult.deactivated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo borrar en Supabase. Se desactivó para que no se vea.'),
            backgroundColor: Colors.amber,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se eliminó solo en este dispositivo (Supabase no respondió / sin permisos).'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirEditor([Promo? promo]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PromoEditor(promo: promo, onSuccess: _cargar),
      ),
    );
  }

  Color _estadoColor(Promo p) {
    if (!p.activa) return Colors.white24;
    if (p.estaVigente) return Colors.greenAccent;
    final now = DateTime.now();
    if (now.isBefore(p.fechaInicio)) return Colors.amber;
    return Colors.redAccent;
  }

  String _estadoTexto(Promo p) {
    if (!p.activa) return 'PAUSADA';
    if (p.estaVigente) return 'EN VIVO';
    final now = DateTime.now();
    if (now.isBefore(p.fechaInicio)) return 'PROGRAMADA';
    return 'FINALIZADA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'PROMOCIONES',
          style: GoogleFonts.bebasNeue(letterSpacing: 2),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
          IconButton(
            tooltip: _mostrarPausadas ? 'Ocultar pausadas' : 'Mostrar pausadas',
            icon: Icon(_mostrarPausadas ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _mostrarPausadas = !_mostrarPausadas);
              _cargar();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirEditor(),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'NUEVA PROMO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
              ),
            )
          : _promos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SIN PROMOCIONES',
                    style: TextStyle(
                      color: Colors.white24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Creá ofertas 2x1, regalos, etc.',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppConstants.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: _promos.length,
                itemBuilder: (_, i) {
                  final p = _promos[i];
                  final estadoColor = _estadoColor(p);
                  return Card(
                    color: AppConstants.cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: p.estaVigente
                            ? AppConstants.primaryColor.withOpacity(0.4)
                            : Colors.white10,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: estadoColor.withOpacity(0.15),
                        child: Text(
                          p.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Text(
                        p.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            p.descripcion,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.vigenciaTexto,
                            style: TextStyle(color: estadoColor, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _estadoTexto(p),
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white54,
                        ),
                        color: AppConstants.darkSurface,
                        onSelected: (v) {
                          if (v == 'edit') _abrirEditor(p);
                          if (v == 'delete') _eliminar(p);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _abrirEditor(p),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class PromoEditor extends StatefulWidget {
  final Promo? promo;
  final VoidCallback? onSuccess;

  const PromoEditor({super.key, this.promo, this.onSuccess});

  @override
  State<PromoEditor> createState() => _PromoEditorState();
}

class _PromoEditorState extends State<PromoEditor> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descripcion = TextEditingController();
  final _etiqueta = TextEditingController();
  final _productoObjetivo = TextEditingController();
  final _descuento = TextEditingController();
  final _repo = PromoRepository();

  String _tipo = 'regalo';
  bool _activa = true;
  late DateTime _inicio;
  late DateTime _fin;
  bool _guardando = false;

  bool get _esEdicion => widget.promo != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (_esEdicion) {
      final p = widget.promo!;
      _titulo.text = p.titulo;
      _descripcion.text = p.descripcion;
      _etiqueta.text = p.etiqueta;
      _productoObjetivo.text = p.productoObjetivo ?? '';
      _descuento.text = p.descuentoPorcentaje > 0
          ? '${p.descuentoPorcentaje}'
          : '';
      _tipo = p.tipo;
      _activa = p.activa;
      _inicio = p.fechaInicio;
      _fin = p.fechaFin;
    } else {
      _inicio = DateTime(now.year, now.month, now.day);
      _fin = _inicio.add(const Duration(days: 7, hours: 23, minutes: 59));
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _etiqueta.dispose();
    _productoObjetivo.dispose();
    _descuento.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final base = esInicio ? _inicio : _fin;
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConstants.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppConstants.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (hora == null) return;

    final elegida = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
    setState(() {
      if (esInicio) {
        _inicio = elegida;
        if (!_fin.isAfter(_inicio)) {
          _fin = _inicio.add(const Duration(days: 1));
        }
      } else {
        _fin = elegida;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_fin.isAfter(_inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior al inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final descuentoPct = int.tryParse(_descuento.text.trim()) ?? 0;
      final promo = Promo(
        id: widget.promo?.id ?? const Uuid().v4(),
        titulo: _titulo.text.trim(),
        descripcion: _descripcion.text.trim(),
        tipo: _tipo,
        etiqueta: _etiqueta.text.trim(),
        activa: _activa,
        fechaInicio: _inicio,
        fechaFin: _fin,
        productoObjetivo: _productoObjetivo.text.trim().isEmpty
            ? null
            : _productoObjetivo.text.trim(),
        descuentoPorcentaje: descuentoPct,
      );

      final synced = await _repo.save(promo, esEdicion: _esEdicion);

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced
                  ? (_esEdicion ? 'Promo actualizada' : 'Promo creada')
                  : 'Promo guardada (sincronización pendiente)',
            ),
            backgroundColor: synced ? Colors.green : Colors.amber,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = AppConstants.primaryColor;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'EDITAR PROMO' : 'NUEVA PROMO',
          style: GoogleFonts.bebasNeue(letterSpacing: 2),
        ),
        backgroundColor: Colors.black,
      ),
      body: _guardando
          ? const Center(child: CircularProgressIndicator(color: accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    dropdownColor: AppConstants.darkSurface,
                    decoration: _inputDeco('Tipo de promo'),
                    items: Promo.tiposLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              '${Promo.tiposEmojis[e.key]} ${e.value}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _tipo = v ?? 'otro'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titulo,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco('Título (ej: 2x1 en clásicas)'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresá un título'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcion,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(
                      'Descripción (ej: Con tu compra, papas con cheddar gratis)',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresá la descripción'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _etiqueta,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(
                      'Etiqueta en banner (ej: 2x1, GRATIS) — opcional',
                    ),
                  ),
                  if (_tipo == '2x1') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _productoObjetivo,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(
                        'Producto objetivo (ej: CLÁSICA, BBQ)',
                      ),
                    ),
                  ],
                  if (_tipo == 'descuento') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descuento,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(
                        'Porcentaje de descuento (ej: 10)',
                      ),
                      validator: (v) {
                        if (_tipo != 'descuento') return null;
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1 || n > 100) {
                          return 'Ingresá un % entre 1 y 100';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  _fechaTile(
                    'Inicio',
                    _inicio,
                    () => _elegirFecha(esInicio: true),
                  ),
                  const SizedBox(height: 10),
                  _fechaTile('Fin', _fin, () => _elegirFecha(esInicio: false)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Promo activa',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Desactivá para pausar sin borrar',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    value: _activa,
                    activeThumbColor: accent,
                    onChanged: (v) => setState(() => _activa = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(
                        _esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR PROMOCIÓN',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppConstants.primaryColor),
      ),
    );
  }

  Widget _fechaTile(String label, DateTime fecha, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      tileColor: AppConstants.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      subtitle: Text(
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(
        Icons.calendar_month,
        color: AppConstants.primaryColor,
      ),
    );
  }
}
