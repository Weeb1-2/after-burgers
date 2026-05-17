import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/promo.dart';
import 'supabase_service.dart';

/// Sincroniza promos con Supabase (filas en `productos` con promo_row:true).
class PromoRepository {
  static const _storageKey = 'after_burgers_promos_v1';

  final SupabaseService _supabase = SupabaseService();

  Future<void> ensureInitialized() async {
    final remote = await _fetchRemote();
    if (remote.isNotEmpty) {
      await _saveLocal(remote);
      return;
    }
    if ((await _loadLocal()).isEmpty) {
      await _seedInicial();
      debugPrint('Promos demo creadas localmente');
    }
  }

  Future<List<Promo>> getAll() async {
    final remote = await _fetchRemote();
    if (remote.isNotEmpty) {
      await _saveLocal(remote);
      return remote;
    }
    await ensureInitialized();
    return _loadLocal();
  }

  Future<List<Promo>> getActivas() async {
    final todas = await getAll();
    return todas.where((p) => p.estaVigente).toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
  }

  Future<void> save(Promo promo, {bool esEdicion = false}) async {
    try {
      Promo guardada;
      // Los IDs de promos pueden ser UUID (String), así que NO podemos inferir
      // "es nueva" con int.tryParse(). El editor sabe si es edición o creación.
      if (esEdicion) {
        try {
          guardada = await _supabase.updatePromocion(promo);
        } catch (_) {
          // Si por algún motivo no existía en remoto, la creamos.
          guardada = await _supabase.createPromocion(promo);
        }
      } else {
        guardada = await _supabase.createPromocion(promo);
      }
      final lista = await _loadLocal();
      final idx = lista.indexWhere((p) => p.id == promo.id);
      if (idx >= 0) {
        lista[idx] = guardada;
      } else {
        lista.add(guardada);
      }
      await _saveLocal(lista);
    } catch (e) {
      debugPrint('Guardando promo solo local: $e');
      final lista = await _loadLocal();
      final idx = lista.indexWhere((p) => p.id == promo.id);
      if (idx >= 0) {
        lista[idx] = promo;
      } else {
        lista.add(promo);
      }
      await _saveLocal(lista);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.deletePromocion(id);
    } catch (e) {
      debugPrint('Eliminar en Supabase falló: $e');
    }
    final lista = await _loadLocal();
    lista.removeWhere((p) => p.id == id);
    await _saveLocal(lista);
  }

  Future<List<Promo>> _fetchRemote() async {
    try {
      return await _supabase.getPromociones();
    } catch (e) {
      debugPrint('Promos remotas no disponibles: $e');
      return [];
    }
  }

  Future<List<Promo>> _seedInicial() async {
    final now = DateTime.now();
    final fin = now.add(const Duration(days: 14));
    final promos = [
      Promo(
        id: 'local-papas',
        titulo: 'Papas con cheddar GRATIS',
        descripcion:
            'Con la compra de cualquier burger te llevás una porción de papas con cheddar',
        tipo: 'regalo',
        etiqueta: 'GRATIS',
        fechaInicio: now,
        fechaFin: fin,
      ),
      Promo(
        id: 'local-2x1',
        titulo: '2x1 en Clásica',
        descripcion:
            'Llevás dos burgers clásicas al precio de una. Válido de lun a jue.',
        tipo: '2x1',
        etiqueta: '2x1',
        productoObjetivo: 'CLÁSICA',
        fechaInicio: now,
        fechaFin: fin,
      ),
    ];
    await _saveLocal(promos);
    return promos;
  }

  Future<List<Promo>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Promo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveLocal(List<Promo> promos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(promos.map((p) => p.toJson()).toList()),
    );
  }
}
