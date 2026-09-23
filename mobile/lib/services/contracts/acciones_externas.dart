/// Acciones que salen de la app: compartir y abrir otras aplicaciones.
abstract class AccionesExternas {
  /// Abre el selector del sistema para compartir. Si [urlImagen] no se puede
  /// descargar, comparte solo el texto.
  Future<void> compartir(String texto, {String? urlImagen});

  /// Abre el enlace en otra app (teléfono, WhatsApp). Devuelve false si no hay
  /// ninguna app que pueda abrirlo.
  Future<bool> abrir(Uri uri);
}
