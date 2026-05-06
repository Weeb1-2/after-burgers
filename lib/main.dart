import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================================
// CONFIGURACIÓN DE SCROLL PARA WEB Y ESCRITORIO
// ==========================================================
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INICIALIZACIÓN DE LA BASE DE DATOS SUPABASE
  await Supabase.initialize(
    url: 'https://mhpbpxqluxnojckatktg.supabase.co',
    anonKey: 'sb_publishable_vlkZa4RFcZgOj6xhFVQ7vQ_QZGx6nfO',
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AfterBurgersEvoApp());
}

// INSTANCIA GLOBAL DE SUPABASE PARA TODA LA APP
final supabase = Supabase.instance.client;

class AfterBurgersEvoApp extends StatelessWidget {
  const AfterBurgersEvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'After Burgers',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainMenuEvo(),
    );
  }
}

// ==========================================================
// MODELOS DE DATOS: CARRITO Y PRODUCTO
// ==========================================================
class CartItem {
  final Burger burger;
  final int personas;
  final List<String> ingredientesQuitados;
  final List<String> adicionalesSumados;
  final int extraPrecio;

  CartItem({
    required this.burger,
    this.personas = 1,
    this.ingredientesQuitados = const [],
    this.adicionalesSumados = const [],
    this.extraPrecio = 0,
  });
}

class Burger {
  final String nombre;
  final String precio;
  final String imagePath;
  final String descripcion;
  final List<String> ingredientes;
  final String categoria;

  Burger({
    required this.nombre,
    required this.precio,
    required this.imagePath,
    required this.descripcion,
    required this.ingredientes,
    this.categoria = 'burgers',
  });
}

class MainMenuEvo extends StatefulWidget {
  const MainMenuEvo({super.key});

  @override
  State<MainMenuEvo> createState() => _MainMenuEvoState();
}

class _MainMenuEvoState extends State<MainMenuEvo> with TickerProviderStateMixin {
  // CONTROLADORES Y VARIABLES DE ESTADO
  late PageController _pageController;
  late AnimationController _shimmerController;
  late AnimationController _cartBadgeController;

  double _currentPage = 0.0;
  List<CartItem> carrito = [];
  int pedidosRealizados = 0;
  String favoritaName = "";
  String nombreGuardado = "";
  String direccionGuardada = "";
  Offset _cartPosition = const Offset(20, 100);
  bool ignoreTimeRestriction = false;
  bool cargandoProductos = true;

  List<Burger> misBurgers = [];

  // DEFINICIÓN DE ADICIONALES DISPONIBLES
  final Map<String, int> adicionalesPrecios = {
    "Huevo": 1500,
    "Medallón extra": 3500,
    "Dip de aderezo": 500,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page!;
        });
      });

    _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2)
    )..repeat();

    _cartBadgeController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300)
    );

    _inicializarApp();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    _cartBadgeController.dispose();
    super.dispose();
  }

  Future<void> _inicializarApp() async {
    await _cargarDatosPersistentes();
    await _obtenerProductosDesdeSupabase();
  }

  // CARGA DE DATOS DESDE SUPABASE
  Future<void> _obtenerProductosDesdeSupabase() async {
    try {
      final data = await supabase.from('productos').select();

      final List<Burger> listaCargada = (data as List).map((res) {
        return Burger(
          nombre: res['nombre'] ?? 'Sin nombre',
          precio: res['precio'].toString(),
          imagePath: res['image_path'] ?? '',
          descripcion: res['descripcion'] ?? '',
          ingredientes: List<String>.from(res['ingredientes'] ?? []),
          categoria: res['categoria'] ?? 'burgers',
        );
      }).toList();

      // INSERTAR PROMOCIÓN MANUAL AL INICIO
      listaCargada.insert(0, Burger(
        nombre: "CLÁSICA + MEDALLÓN",
        precio: "11500",
        imagePath: "assets/images/promo_clasica.png",
        descripcion: "Nuestra clásica burger con un medallón extra de carne y porción de papas.",
        ingredientes: ["Doble Carne", "Doble Cheddar", "Papas Fritas"],
      ));

      setState(() {
        misBurgers = listaCargada;
        cargandoProductos = false;
        _actualizarFavorita();
      });
    } catch (e) {
      debugPrint("Error cargando productos: $e");
      setState(() {
        cargandoProductos = false;
      });
    }
  }

  Future<void> _cargarDatosPersistentes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pedidosRealizados = prefs.getInt('pedidos_count') ?? 0;
      nombreGuardado = prefs.getString('cliente_nombre') ?? "";
      direccionGuardada = prefs.getString('cliente_direccion') ?? "";
    });
  }

  void _actualizarFavorita() {
    if (misBurgers.isEmpty) return;
    SharedPreferences.getInstance().then((prefs) {
      String maxKey = "";
      int maxVal = 0;
      for (var b in misBurgers) {
        int count = prefs.getInt('count_${b.nombre}') ?? 0;
        if (count > maxVal) {
          maxVal = count;
          maxKey = b.nombre;
        }
      }
      if (maxVal > 2) {
        setState(() {
          favoritaName = maxKey;
        });
      }
    });
  }

  // LÓGICA DE HORARIOS
  bool get estaAbierto {
    if (ignoreTimeRestriction) return true;
    final now = DateTime.now();
    return now.hour >= 21 || now.hour < 3;
  }

  String get rangoActual {
    if (pedidosRealizados < 5) return "NOVATO 🥩";
    if (pedidosRealizados < 15) return "BURGER LOVER 🍔";
    return "AFTER LEGEND 👑";
  }

  // ACCESO ADMIN
  void _mostrarLoginAdmin() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00E5FF))
        ),
        title: Text("ACCESO RESTRINGIDO", style: GoogleFonts.bebasNeue(color: const Color(0xFF00E5FF))),
        content: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              labelText: "Contraseña",
              labelStyle: TextStyle(color: Colors.white38)
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")
          ),
          ElevatedButton(
            onPressed: () {
              if (passController.text == "31647601") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const KitchenPanel()));
              }
            },
            child: const Text("ENTRAR"),
          )
        ],
      ),
    );
  }

  // CARRITO Y PERSISTENCIA
  void _agregarAlCarrito(Burger burger, {int personas = 1, List<String> quitados = const [], List<String> adicionales = const [], int extraPrecio = 0}) {
    if (!estaAbierto) {
      _showClosedNotice();
      return;
    }

    HapticFeedback.mediumImpact();
    _cartBadgeController.forward(from: 0.0);

    setState(() {
      carrito.add(CartItem(
          burger: burger,
          personas: personas,
          ingredientesQuitados: List.from(quitados),
          adicionalesSumados: List.from(adicionales),
          extraPrecio: extraPrecio
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${burger.nombre} añadida al carrito"),
        backgroundColor: const Color(0xFF00E5FF).withOpacity(0.9),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showClosedNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Solo aceptamos pedidos de 21:00 a 03:00 hs."),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _mostrarFormularioDatos() {
    final nameController = TextEditingController(text: nombreGuardado);
    final addressController = TextEditingController(text: direccionGuardada);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text("DATOS DE ENTREGA", style: GoogleFonts.bebasNeue(color: const Color(0xFF00E5FF), fontSize: 24, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Tu Nombre", labelStyle: TextStyle(color: Colors.white38)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: "Dirección Exacta", labelStyle: TextStyle(color: Colors.white38)),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.white24))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty && addressController.text.trim().isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('cliente_nombre', nameController.text.trim());
                await prefs.setString('cliente_direccion', addressController.text.trim());

                setState(() {
                  nombreGuardado = nameController.text.trim();
                  direccionGuardada = addressController.text.trim();
                });

                Navigator.pop(context);
                _procesarPedidoConAnimacion();
              }
            },
            child: const Text("CONFIRMAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarEnSupabase() async {
    try {
      final total = carrito.fold(0, (sum, item) => sum + ((int.parse(item.burger.precio) + item.extraPrecio) * item.personas));
      await supabase.from('pedidos').insert({
        'cliente': nombreGuardado,
        'direccion': direccionGuardada,
        'total': total,
        'items': carrito.map((item) => {
          'nombre': item.burger.nombre,
          'cantidad': item.personas,
          'sin': item.ingredientesQuitados,
          'adicionales': item.adicionalesSumados
        }).toList(),
        'rango': rangoActual,
      });
    } catch (e) {
      debugPrint("Error guardando en Supabase: $e");
    }
  }

  void _procesarPedidoConAnimacion() {
    if (carrito.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 3000), () async {
          if (mounted) {
            await _guardarEnSupabase();
            Navigator.pop(context);
            _enviarWhatsApp();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/Ready For Delivery.json',
                width: 250,
                repeat: true,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.delivery_dining, size: 100, color: Color(0xFF00E5FF)),
              ),
              const SizedBox(height: 20),
              Text(
                "¡MARCHANDO!",
                style: GoogleFonts.bebasNeue(
                  color: const Color(0xFF00E5FF),
                  fontSize: 28,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enviarWhatsApp() async {
    final prefs = await SharedPreferences.getInstance();

    int nuevosPedidos = pedidosRealizados + 1;
    await prefs.setInt('pedidos_count', nuevosPedidos);

    for (var item in carrito) {
      int countActual = prefs.getInt('count_${item.burger.nombre}') ?? 0;
      await prefs.setInt('count_${item.burger.nombre}', countActual + 1);
    }

    const String numero = "5493541612565";
    String mensaje = "🍔 *NUEVO PEDIDO: AFTER BURGERS*\n";
    mensaje += "--------------------------\n";
    mensaje += "👤 *CLIENTE:* $nombreGuardado\n";
    mensaje += "📍 *ENTREGA:* $direccionGuardada\n";
    mensaje += "🎖️ *NIVEL:* $rangoActual\n";
    mensaje += "⏰ *HORA:* ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} hs\n";
    mensaje += "--------------------------\n";

    int total = 0;
    for (var item in carrito) {
      int subtotal = (int.parse(item.burger.precio) + item.extraPrecio) * item.personas;
      mensaje += "• *${item.burger.nombre}* (\$${(int.parse(item.burger.precio) + item.extraPrecio)})\n";

      if (item.personas > 1) {
        mensaje += "  ↳ Cantidad: ${item.personas}\n";
      }

      if (item.ingredientesQuitados.isNotEmpty) {
        mensaje += "  ↳ _SIN: ${item.ingredientesQuitados.join(', ')}_\n";
      }

      if (item.adicionalesSumados.isNotEmpty) {
        mensaje += "  ↳ _EXTRA: ${item.adicionalesSumados.join(', ')}_\n";
      }

      total += subtotal;
    }

    mensaje += "\n💰 *TOTAL A PAGAR: \$${total}*";

    final Uri whatsappUri = Uri.parse("whatsapp://send?phone=$numero&text=${Uri.encodeComponent(mensaje)}");
    final Uri webUri = Uri.parse("https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}");

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      setState(() {
        carrito.clear();
        pedidosRealizados = nuevosPedidos;
        _actualizarFavorita();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir WhatsApp")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF00E5FF);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(accent),
                if (!estaAbierto) _buildClosedBanner(),
                Expanded(
                  child: cargandoProductos
                      ? const Center(child: CircularProgressIndicator(color: accent))
                      : PageView.builder(
                    controller: _pageController,
                    itemCount: misBurgers.length,
                    itemBuilder: (context, index) {
                      double delta = (_currentPage - index).abs();
                      return Transform.scale(
                        scale: (1 - (delta * 0.12)).clamp(0.8, 1.0),
                        child: Opacity(
                          opacity: (1 - (delta * 0.5)).clamp(0.0, 1.0),
                          child: _buildBurgerCard(misBurgers[index], accent),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (carrito.isNotEmpty)
            Positioned(
              left: _cartPosition.dx,
              bottom: _cartPosition.dy,
              child: Draggable(
                feedback: Material(
                  color: Colors.transparent,
                  child: _buildFAB(accent),
                ),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() {
                    double newY = MediaQuery.of(context).size.height - details.offset.dy - 60;
                    _cartPosition = Offset(
                        details.offset.dx,
                        newY.clamp(20.0, MediaQuery.of(context).size.height - 150)
                    );
                  });
                },
                child: _buildFAB(accent),
              ),
            ),
        ],
      ),
    );
  }

  // WIDGETS DE SOPORTE UI
  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      color: Colors.redAccent.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Center(
        child: Text(
          "LOCAL CERRADO - ABRIMOS DE 21:00 A 03:00",
          style: TextStyle(
              color: Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(Color accent) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _cartBadgeController, curve: Curves.elasticOut)
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _mostrarCarrito(accent),
        backgroundColor: accent,
        elevation: 10,
        label: Text(
            "${carrito.length}",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onLongPress: _mostrarLoginAdmin,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AFTER", style: GoogleFonts.bebasNeue(fontSize: 14, letterSpacing: 5, color: Colors.white24)),
                Text("BURGERS", style: GoogleFonts.bebasNeue(fontSize: 32, fontWeight: FontWeight.bold, color: accent)),
              ],
            ),
          ),
          GestureDetector(
            onLongPress: () {
              setState(() => ignoreTimeRestriction = !ignoreTimeRestriction);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Restricción horaria: ${ignoreTimeRestriction ? 'OFF' : 'ON'}"))
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
              child: Text(
                  rangoActual,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)
              ),
            ),
          )
        ],
      ),
    );
  }

  void _mostrarCarrito(Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(30),
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Text("RESUMEN DE PEDIDO", style: GoogleFonts.bebasNeue(fontSize: 24, letterSpacing: 2)),
                const Divider(color: Colors.white10, height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: carrito.length,
                    itemBuilder: (context, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(carrito[i].burger.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          (carrito[i].ingredientesQuitados.isEmpty && carrito[i].adicionalesSumados.isEmpty)
                              ? (carrito[i].personas > 1 ? "Para ${carrito[i].personas} personas" : "Completa")
                              : "Pers. / Extras",
                          style: const TextStyle(color: Colors.white38, fontSize: 12)
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              "\$${(int.parse(carrito[i].burger.precio) + carrito[i].extraPrecio) * carrito[i].personas}",
                              style: TextStyle(color: accent, fontWeight: FontWeight.bold)
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                            onPressed: () {
                              setModalState(() => carrito.removeAt(i));
                              setState(() {});
                              if (carrito.isEmpty) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL ESTIMADO", style: TextStyle(color: Colors.white54)),
                      Text(
                          "\$${carrito.fold(0, (sum, item) => sum + ((int.parse(item.burger.precio) + item.extraPrecio) * item.personas))}",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 65),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  onPressed: () {
                    if (!estaAbierto) {
                      Navigator.pop(context);
                      _showClosedNotice();
                    } else {
                      Navigator.pop(context);
                      _mostrarFormularioDatos();
                    }
                  },
                  child: const Text("FINALIZAR PEDIDO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBurgerCard(Burger burger, Color accent) {
    bool isFavorita = burger.nombre == favoritaName;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
              color: isFavorita ? accent.withOpacity(0.3) : Colors.white.withOpacity(0.05),
              width: isFavorita ? 2 : 1
          )
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                  flex: 4,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            burger.imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.white10,
                                child: const Icon(Icons.fastfood, size: 50)
                            ),
                          )
                      )
                  )
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(burger.nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("\$${burger.precio}", style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text("🍟 Incluye porción de papas fritas", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(burger.descripcion, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 25),
                    _buildMainButton(burger, accent),
                    const SizedBox(height: 12),
                    _buildExtraButtons(burger, accent),
                  ],
                ),
              )
            ],
          ),
          if (isFavorita) Positioned(
            top: 30, right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
              child: const Text("TU FAVORITA ⭐", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMainButton(Burger burger, Color accent) {
    bool closed = !estaAbierto;
    return GestureDetector(
      onTap: () => _agregarAlCarrito(burger),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) => Container(
          height: 60, width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: closed ? Colors.white10 : null,
            gradient: closed ? null : LinearGradient(
              colors: [accent, Colors.white.withOpacity(0.7), accent],
              stops: [
                (_shimmerController.value - 0.2).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.2).clamp(0.0, 1.0)
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Center(
              child: Text(
                  closed ? "PEDIR A PARTIR DE LAS 21:00" : "AGREGAR AL CARRITO",
                  style: TextStyle(
                      color: closed ? Colors.white24 : Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11
                  )
              )
          ),
        ),
      ),
    );
  }

  Widget _buildExtraButtons(Burger burger, Color accent) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showGroupOrder(burger, accent),
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 15)
            ),
            child: const Text("PARA VARIOS", style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
            onPressed: () => _showCustomization(burger, accent),
            icon: Icon(Icons.tune, color: accent, size: 28)
        )
      ],
    );
  }

  void _showGroupOrder(Burger burger, Color accent) {
    if (!estaAbierto) {
      _showClosedNotice();
      return;
    }
    int cantidad = 2;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("¿CUÁNTAS PERSONAS COMEN?", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _counterBtn(Icons.remove, () => setModalState(() { if(cantidad > 1) cantidad--; })),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text("$cantidad", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: accent)),
                  ),
                  _counterBtn(Icons.add, () => setModalState(() { cantidad++; })),
                ]),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _agregarAlCarrito(burger, personas: cantidad);
                  },
                  child: const Text("CONFIRMAR GRUPO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback tap) => GestureDetector(
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(10)
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );

  void _showCustomization(Burger burger, Color accent) {
    if (!estaAbierto) {
      _showClosedNotice();
      return;
    }

    List<String> quitadosLocal = [];
    List<String> adicionalesLocal = [];
    int extraAcumulado = 0;

    final opciones = burger.ingredientes.where((ing) => ing.toLowerCase() != "carne").toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("PERSONALIZAR", style: GoogleFonts.bebasNeue(fontSize: 22)),
                const Text("Quitar ingredientes:", style: TextStyle(color: Colors.white24, fontSize: 11)),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...opciones.map((ing) => CheckboxListTile(
                          title: Text(ing, style: const TextStyle(fontSize: 14)),
                          value: !quitadosLocal.contains(ing),
                          activeColor: accent,
                          onChanged: (val) => setMState(() {
                            val! ? quitadosLocal.remove(ing) : quitadosLocal.add(ing);
                          }),
                        )),
                        const Divider(color: Colors.white10),
                        const Text("AGREGAR EXTRAS:", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        ...adicionalesPrecios.entries.map((entry) => CheckboxListTile(
                          title: Text("${entry.key} (+\$${entry.value})", style: const TextStyle(fontSize: 14)),
                          value: adicionalesLocal.contains(entry.key),
                          activeColor: Colors.amber,
                          onChanged: (val) => setMState(() {
                            if (val!) {
                              adicionalesLocal.add(entry.key);
                              extraAcumulado += entry.value;
                            } else {
                              adicionalesLocal.remove(entry.key);
                              extraAcumulado -= entry.value;
                            }
                          }),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      minimumSize: const Size(double.infinity, 55)
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _agregarAlCarrito(
                        burger,
                        quitados: quitadosLocal,
                        adicionales: adicionalesLocal,
                        extraPrecio: extraAcumulado
                    );
                  },
                  child: const Text("GUARDAR Y AÑADIR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// PANEL DE COCINA: GESTIÓN DE PEDIDOS EN TIEMPO REAL
// ==========================================================
class KitchenPanel extends StatelessWidget {
  const KitchenPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("COCINA - PEDIDOS", style: GoogleFonts.bebasNeue(letterSpacing: 2)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('pedidos').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          }

          final pedidos = snapshot.data!;

          if (pedidos.isEmpty) {
            return const Center(
                child: Text("NO HAY PEDIDOS PENDIENTES", style: TextStyle(color: Colors.white24))
            );
          }

          return ListView.builder(
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final p = pedidos[index];
              return Card(
                color: const Color(0xFF111111),
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                      "${p['cliente']} - \$${p['total']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                        "📍 ${p['direccion']}\n🍔 Items: ${p['items']}",
                        style: const TextStyle(color: Colors.white70, fontSize: 13)
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30),
                    onPressed: () async {
                      await supabase.from('pedidos').delete().match({'id': p['id']});
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