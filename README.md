# 🍔 After Burgers - Mobile Experience

Una aplicación Flutter moderna para delivery de hamburguesas con gestión de pedidos en tiempo real.

## ✨ Características

### Para el Cliente
- 📱 Catálogo de productos con diseño atractivo
- 🛒 Carrito de compras con persistencia local
- 🎨 Personalización de pedidos (quitar/agregar ingredientes)
- ⭐ Sistema de favoritos basado en historial
- 🎯 Gamification con rangos (Novato, Burger Lover, After Legend)
- 📲 Envío de pedidos vía WhatsApp
- 🌙 Diseño dark mode moderno

### Para el Administrador
- 👨‍🍳 Panel de cocina en tiempo real
- 📊 Gestión completa de productos (CRUD)
- 📸 Subida de imágenes desde galería/cámara
- 🏷️ Categorización de productos
- 💰 Control de precios y descripciones

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── app.dart                  # Configuración principal y pantallas
├── config/
│   ├── constants.dart        # Constantes de la app (colores, textos)
│   └── env.dart              # Configuración de variables de entorno
├── models/
│   ├── burger.dart           # Modelo de producto
│   └── cart_item.dart        # Modelo de item del carrito
├── services/
│   ├── supabase_service.dart # Servicio de base de datos
│   └── storage_service.dart  # Servicio de almacenamiento de imágenes
├── screens/
│   └── admin_panel.dart      # Panel de administración
└── widgets/
    └── burger_card.dart      # Widget de tarjeta de producto
```

## 🚀 Configuración e Instalación

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/after-burgers.git
cd after-burgers
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar variables de entorno

1. Copia el archivo de ejemplo:
```bash
cp .env.example .env
```

2. Edita `.env` con tus credenciales:
```env
# Supabase Configuration
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_anon_key

# Admin Configuration
ADMIN_PASSWORD=tu_contraseña

# WhatsApp Configuration
WHATSAPP_NUMBER=tu_numero_con_codigo_pais

# Horarios (formato 24h)
OPENING_HOUR=21
CLOSING_HOUR=3

# Supabase Storage Bucket
STORAGE_BUCKET=productos-imagenes
```

### 4. Configurar Supabase

#### Crear tablas en Supabase

**Tabla `productos`:**
```sql
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre TEXT NOT NULL,
  precio INTEGER NOT NULL,
  descripcion TEXT,
  ingredientes JSONB DEFAULT '[]',
  categoria TEXT DEFAULT 'burgers',
  image_path TEXT,
  orden INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

> **Orden del menú (opcional):** si querés controlar manualmente el orden en el que aparecen las hamburguesas, agregá la columna `orden` (si tu tabla ya existe):
```sql
alter table public.productos add column if not exists orden integer;
create index if not exists productos_orden_idx on public.productos (orden);
```

**Tabla `pedidos`:**
```sql
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cliente TEXT NOT NULL,
  direccion TEXT NOT NULL,
  total INTEGER NOT NULL,
  items JSONB NOT NULL,
  rango TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Configurar Storage

1. Ve a Supabase Storage
2. Crea un bucket público llamado `productos-imagenes`
3. Configura las políticas de acceso para permitir lectura pública

## 🛠️ Tecnologías Utilizadas

- **Flutter** - Framework multiplataforma
- **Supabase** - Backend como servicio (Base de datos, Auth, Storage)
- **SharedPreferences** - Persistencia local
- **Lottie** - Animaciones
- **Google Fonts** - Tipografía
- **Image Picker** - Selección de imágenes
- **Cached Network Image** - Caché de imágenes

## 🔐 Seguridad

### Variables de Entorno
Las credenciales sensibles están en el archivo `.env` que **NO** debe subirse al repositorio (está en `.gitignore`).

### Contraseña de Admin
La contraseña de administrador se configura en el `.env` y se usa para acceder a:
- Panel de Cocina (ver pedidos en tiempo real)
- Administración de Productos (CRUD de menú)

## 📱 Uso de la Aplicación

### Modo Cliente
1. Abre la app y navega por el menú deslizando horizontalmente
2. Toca "AGREGAR AL CARRITO" para añadir productos
3. Personaliza tu pedido (ingredientes, cantidad, extras)
4. Revisa tu carrito (botón flotante arrastrable)
5. Completa tus datos de entrega
6. El pedido se envía por WhatsApp automáticamente

### Modo Administrador
1. Mantén presionado el logo "AFTER BURGERS" en el header
2. Ingresa la contraseña de administrador
3. Selecciona entre:
   - **Cocina - Pedidos**: Ver pedidos en tiempo real
   - **Administrar Productos**: Gestionar el menú

## 🔧 Comandos Útiles

### Desarrollo
```bash
# Ejecutar en modo debug
flutter run

# Ejecutar análisis de código
flutter analyze

# Formatear código
dart format .
```

### Build
```bash
# Build para Android
flutter build apk --release

# Build para iOS
flutter build ios --release

# Build para Web
flutter build web
```

## 📂 Estructura de la Base de Datos

### Productos
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| nombre | TEXT | Nombre del producto |
| precio | INTEGER | Precio en pesos |
| descripcion | TEXT | Descripción del producto |
| ingredientes | JSONB | Lista de ingredientes |
| categoria | TEXT | Categoría (burgers, bebidas, etc.) |
| image_path | TEXT | URL de la imagen |
| created_at | TIMESTAMP | Fecha de creación |

### Pedidos
| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | UUID | Identificador único |
| cliente | TEXT | Nombre del cliente |
| direccion | TEXT | Dirección de entrega |
| total | INTEGER | Total del pedido |
| items | JSONB | Lista de items pedidos |
| rango | TEXT | Rango del cliente |
| created_at | TIMESTAMP | Fecha del pedido |

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 👨‍💻 Desarrollo

### Dependencias Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.12.4
  shared_preferences: ^2.2.2
  google_fonts: ^6.2.1
  lottie: ^3.1.0
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  flutter_dotenv: ^5.1.0
  uuid: ^4.3.3
```

## 🐛 Problemas Conocidos

- Las imágenes locales (assets) no se pueden eliminar desde el admin panel
- El horario de cierre cruzado (ej: 21:00 a 03:00) puede tener edge cases

## 📞 Soporte

Para soporte, envía un email a tu-email@ejemplo.com o únete a nuestro canal de Discord.

---

**Hecho con ❤️ usando Flutter**
