import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../contracts/acciones_externas.dart';

class AccionesExternasPlataforma implements AccionesExternas {
  @override
  Future<void> compartir(String texto, {String? urlImagen}) async {
    final imagen = urlImagen == null ? null : await _imagenPng(urlImagen);
    await SharePlus.instance.share(
      ShareParams(
        text: texto,
        files: imagen == null
            ? null
            : [XFile.fromData(imagen, mimeType: 'image/png')],
        fileNameOverrides: imagen == null ? null : ['mascota.png'],
      ),
    );
  }

  /// La API sirve WebP; algunas apps (WhatsApp) lo tratan como sticker, así
  /// que se convierte a PNG. Ante cualquier fallo se comparte sin imagen.
  Future<Uint8List?> _imagenPng(String url) async {
    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (respuesta.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(respuesta.bodyBytes);
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return png?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> abrir(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
