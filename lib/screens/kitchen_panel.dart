import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants.dart';
import '../services/supabase_service.dart';
import '../utils/price_formatter.dart';

class KitchenPanel extends StatelessWidget {
  const KitchenPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'COCINA - PEDIDOS',
          style: GoogleFonts.bebasNeue(letterSpacing: 2),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService().getPedidosStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.primaryColor),
            );
          }

          final pedidos = snapshot.data!;

          if (pedidos.isEmpty) {
            return const Center(
              child: Text(
                'NO HAY PEDIDOS PENDIENTES',
                style: TextStyle(color: Colors.white24),
              ),
            );
          }

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final p = pedidos[index];
              final total = p['total'];
              final totalStr = total is int
                  ? PriceFormatter.format(total)
                  : total?.toString() ?? '';

              return Card(
                color: AppConstants.cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    '${p['cliente']} - $totalStr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '📍 ${p['direccion']}\n🍔 Items: ${p['items']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 30,
                    ),
                    onPressed: () async {
                      await SupabaseService().deletePedido(p['id'].toString());
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
