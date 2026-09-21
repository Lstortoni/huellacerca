import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../models/foto_seleccionada.dart';
import '../contracts/selector_fotos.dart';

class SelectorFotosGaleria implements SelectorFotos {
  final _picker = ImagePicker();
  Future<FotoSeleccionada?> _leer(XFile? file) async {
    if (file == null) return null;
    if (await file.length() > 10 * 1024 * 1024) {
      throw const ApiException(
        'La foto es demasiado grande. Elegí una de hasta 10 MB.',
      );
    }
    return FotoSeleccionada(await file.readAsBytes());
  }

  @override
  Future<FotoSeleccionada?> elegir() async => _leer(
    await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 75,
      requestFullMetadata: false,
    ),
  );
  @override
  Future<FotoSeleccionada?> recuperar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final data = await _picker.retrieveLostData();
    if (data.exception != null) {
      throw const ApiException(
        'No pudimos recuperar la foto seleccionada. Elegila nuevamente.',
      );
    }
    return _leer(data.files?.firstOrNull);
  }
}
