# 📱 Configuración para Android Studio

## ✅ Proyecto Listo para Android Studio

Tu proyecto Flutter ha sido completamente configurado y está listo para ejecutarse en Android Studio.

## 🚀 Pasos para Abrir en Android Studio

### 1. Abrir el Proyecto
1. Inicia **Android Studio**
2. Selecciona **"Open an Existing Project"** (Abrir proyecto existente)
3. Navega a la carpeta: `c:\Users\Admin\AndroidStudioProjects\Burguer_app`
4. Haz clic en **"OK"**

### 2. Esperar la Indexación
- Android Studio automáticamente:
  - Indexará los archivos del proyecto
  - Descargará las dependencias de Dart/Flutter
  - Configurar el SDK de Flutter

### 3. Verificar Configuración
1. Ve a **File → Project Structure** (o presiona `Ctrl+Alt+Shift+S`)
2. En **"SDKs"** verifica que esté configurado:
   - **Flutter SDK**: `C:\develop\flutter`
   - **Android SDK**: `C:\Users\Admin\AppData\Local\Android\sdk`
   - **Java**: `OpenJDK 21` (o la versión que tengas)

### 4. Ejecutar la App
1. Conecta un dispositivo Android o inicia un emulador
2. En la barra de herramientas, selecciona el dispositivo
3. Haz clic en el botón **"Run"** (▶️ verde) o presiona `Shift+F10`

## 🔧 Comandos Útiles desde la Terminal de Android Studio

```bash
# Limpiar proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Verificar configuración
flutter doctor -v

# Ejecutar en dispositivo conectado
flutter run

# Ejecutar en emulador específico
flutter run -d <emulator_id>

# Build para Android (release)
flutter build apk --release
```

## 📁 Archivos de Configuración del Proyecto

El proyecto ya incluye todos los archivos necesarios:

- ✅ `.idea/` - Configuración de Android Studio
- ✅ `android/` - Configuración nativa de Android
- ✅ `pubspec.yaml` - Dependencias de Flutter
- ✅ `.env` - Variables de entorno (NO subir a Git)
- ✅ `.gitignore` - Configurado correctamente

## 🐛 Solución de Problemas Comunes

### Problema: "Flutter SDK not found"
**Solución**: 
1. Ve a **File → Settings → Languages & Frameworks → Flutter**
2. Establece el path: `C:\develop\flutter`
3. Aplica y reinicia Android Studio

### Problema: "Dependencies not resolved"
**Solución**:
1. Abre la terminal en Android Studio
2. Ejecuta: `flutter clean && flutter pub get`
3. Reinicia Android Studio

### Problema: "No devices available"
**Solución**:
- Conecta un dispositivo Android por USB con depuración activada
- O crea un emulador: **Tools → Device Manager → Create Device**

### Problema: Errores de compilación
**Solución**:
```bash
flutter clean
flutter pub get
flutter run
```

## 🎯 Características del Proyecto

### Estructura de Carpetas
```
burguer_app/
├── lib/                    # Código Dart
│   ├── main.dart          # Punto de entrada
│   ├── app.dart           # App principal
│   ├── config/            # Configuración
│   ├── models/            # Modelos de datos
│   ├── services/          # Servicios (Supabase)
│   ├── screens/           # Pantallas
│   └── widgets/           # Widgets reutilizables
├── android/               # Configuración Android
├── ios/                   # Configuración iOS
├── web/                   # Versión web
├── assets/                # Imágenes y recursos
├── pubspec.yaml           # Dependencias
├── .env                   # Variables de entorno
└── README.md              # Documentación
```

### Dependencias Principales
- `supabase_flutter`: Base de datos en tiempo real
- `flutter_dotenv`: Variables de entorno
- `image_picker`: Selección de imágenes
- `cached_network_image`: Caché de imágenes
- `google_fonts`: Tipografías
- `lottie`: Animaciones
- `url_launcher`: Abrir URLs (WhatsApp)

## 📝 Notas Importantes

1. **Archivo .env**: Contiene credenciales sensibles. **NUNCA** lo subas a Git.
2. **Supabase**: Asegúrate de que tu proyecto de Supabase esté configurado correctamente.
3. **Permisos Android**: Los permisos de cámara y almacenamiento ya están configurados en `AndroidManifest.xml`.
4. **Hot Reload**: Usa `Ctrl+S` para hot reload mientras desarrollas.

## 🆘 Soporte

Si tienes problemas:
1. Revisa `flutter doctor -v`
2. Limpia el proyecto: `flutter clean`
3. Reinicia Android Studio
4. Verifica que el archivo `.env` exista y tenga las credenciales correctas

## ✨ ¡Listo!

Tu proyecto está completamente configurado y debería funcionar sin problemas en Android Studio. 

**¡A codificar! 🚀**