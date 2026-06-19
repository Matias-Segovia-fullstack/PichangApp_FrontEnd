import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  /// Permite seleccionar una foto, comprimirla a formato WebP y subirla a Supabase Storage.
  /// Retorna la URL pública de la imagen subida, o null si el usuario canceló la operación.
  Future<String?> pickCompressAndUploadImage({
    required String bucket,
    required String folder,
    int quality = 80,
  }) async {
    try {
      // 1. Seleccionar la imagen desde galería
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Traemos la máxima calidad para comprimirla nosotros mismos
      );

      if (pickedFile == null) {
        debugPrint('Selección de imagen cancelada');
        return null;
      }

      final File fileToUpload = File(pickedFile.path);
      
      // 3. Generar un nombre único de archivo
      final String fileExtension = kIsWeb ? pickedFile.name.split('.').last : 'webp';
      final String fileName = '${DateTime.now().microsecondsSinceEpoch}.$fileExtension';
      final String uploadPath = '$folder/$fileName';

      if (kIsWeb) {
        // COMPORTAMIENTO WEB: Trabajar directamente en memoria (bytes)
        final Uint8List fileBytes = await pickedFile.readAsBytes();
        
        debugPrint('Subiendo imagen desde Web a Supabase: $uploadPath');
        await _supabase.storage.from(bucket).uploadBinary(
              uploadPath,
              fileBytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );
      } else {
        // COMPORTAMIENTO MÓVIL: Comprimir usando paths nativos
        final tempDir = await getTemporaryDirectory();
        final String targetPath = '${tempDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.webp';

        debugPrint('Iniciando compresión de imagen a WebP...');
        final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
          fileToUpload.absolute.path,
          targetPath,
          format: CompressFormat.webp,
          quality: quality,
        );

        if (compressedFile == null) {
          throw Exception('Error al comprimir la imagen');
        }

        final File finalImage = File(compressedFile.path);
        debugPrint('Compresión completada. Tamaño final: ${await finalImage.length()} bytes');

        debugPrint('Subiendo imagen a Supabase: $uploadPath');
        await _supabase.storage.from(bucket).upload(
              uploadPath,
              finalImage,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );

        // Limpieza local del archivo temporal
        try {
          await finalImage.delete();
        } catch (_) {}
      }

      // 5. Obtener y retornar la URL pública
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(uploadPath);
      debugPrint('Subida exitosa. URL Pública: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error en pickCompressAndUploadImage: $e');
      rethrow;
    }
  }

  /// Permite seleccionar un video, comprimirlo a un formato MP4 liviano y subirlo a Supabase Storage.
  /// Retorna la URL pública del video subido, o null si se canceló.
  Future<String?> pickCompressAndUploadVideo({
    required String bucket,
    required String folder,
    VideoQuality videoQuality = VideoQuality.MediumQuality,
    Function(double)? onProgress,
  }) async {
    try {
      // 1. Seleccionar el video desde la galería
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3), // Límite de duración amigable
      );

      if (pickedFile == null) {
        debugPrint('Selección de video cancelada');
        return null;
      }

      // 2. Suscribirse al progreso de la compresión
      Subscription? subscription;
      if (onProgress != null) {
        subscription = VideoCompress.compressProgress$.subscribe((progress) {
          onProgress(progress);
        });
      }

      debugPrint('Iniciando compresión de video...');
      // 3. Iniciar compresión (genera un MP4 optimizado en caché temporal)
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        pickedFile.path,
        quality: videoQuality,
        deleteOrigin: false, // No borramos el original del carrete del usuario
        includeAudio: true,
      );

      // Cancelar suscripción al terminar la compresión
      subscription?.unsubscribe();

      if (mediaInfo == null || mediaInfo.path == null) {
        throw Exception('La compresión del video falló');
      }

      final File compressedVideoFile = File(mediaInfo.path!);
      debugPrint('Video comprimido con éxito. Tamaño final: ${await compressedVideoFile.length()} bytes');

      // 4. Generar nombre único
      final String fileName = '${DateTime.now().microsecondsSinceEpoch}.mp4';
      final String uploadPath = '$folder/$fileName';

      // 5. Subir a Supabase Storage
      debugPrint('Subiendo video a Supabase: $uploadPath');
      await _supabase.storage.from(bucket).upload(
            uploadPath,
            compressedVideoFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 6. Obtener la URL pública
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(uploadPath);
      debugPrint('Subida exitosa. URL Pública del video: $publicUrl');

      // 7. Limpiar caché temporal de la librería
      await VideoCompress.deleteAllCache();

      return publicUrl;
    } catch (e) {
      debugPrint('Error en pickCompressAndUploadVideo: $e');
      // Asegurarse de limpiar la caché en caso de fallo
      await VideoCompress.deleteAllCache();
      rethrow;
    }
  }
}
