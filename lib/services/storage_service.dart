import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();

  // ==================== IMAGE PICKER ====================

  // Seleccionar imagen de la galería
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Error seleccionando imagen: $e');
    }
  }

  // Tomar foto con la cámara
  Future<XFile?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      throw Exception('Error tomando foto: $e');
    }
  }

  // ==================== SUPABASE STORAGE ====================

  // Subir imagen a Supabase Storage
  Future<String> uploadImageToStorage(
    XFile imageFile, {
    String? bucket,
    String? folder,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final bucketName = bucket ?? EnvConfig.storageBucket;
      
      // Leer el archivo
      final bytes = await imageFile.readAsBytes();
      
      // Generar nombre único
      final extension = imageFile.name.split('.').last;
      final fileName = '${folder ?? 'productos'}/${_uuid.v4()}.$extension';
      
      // Subir a Supabase
      await supabase.storage
          .from(bucketName)
          .uploadBinary(fileName, bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );
      
      // Obtener URL pública
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Error subiendo imagen: $e');
    }
  }

  // Eliminar imagen de Supabase Storage
  Future<void> deleteImageFromStorage(
    String imageUrl, {
    String? bucket,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final bucketName = bucket ?? EnvConfig.storageBucket;
      
      // Extraer el path del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments
          .skipWhile((segment) => segment != bucketName)
          .skip(1)
          .join('/');
      
      if (path.isNotEmpty) {
        await supabase.storage.from(bucketName).remove([path]);
      }
    } catch (e) {
      // No lanzar error si la imagen ya no existe
      print('Error eliminando imagen (puede que ya no exista): $e');
    }
  }

  // ==================== UTILIDADES ====================

  // Convertir XFile a File (para compatibilidad)
  File xFileToFile(XFile xFile) {
    return File(xFile.path);
  }

  // Obtener el tamaño del archivo en KB
  Future<int> getFileSizeKB(XFile xFile) async {
    final file = xFileToFile(xFile);
    final bytes = await file.length();
    return (bytes / 1024).round();
  }
}