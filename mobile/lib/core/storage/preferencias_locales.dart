import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferencias chicas de este teléfono (por ejemplo, ubicaciones recientes).
/// No es para la sesión: esa usa SessionStorage.
abstract class PreferenciasLocales {
  Future<String?> leer(String clave);
  Future<void> guardar(String clave, String valor);
}

class PreferenciasSeguras implements PreferenciasLocales {
  const PreferenciasSeguras();
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> leer(String clave) => _storage.read(key: clave);
  @override
  Future<void> guardar(String clave, String valor) =>
      _storage.write(key: clave, value: valor);
}

/// Para pruebas y para cuando no hay almacenamiento disponible.
class PreferenciasEnMemoria implements PreferenciasLocales {
  final _valores = <String, String>{};
  @override
  Future<String?> leer(String clave) async => _valores[clave];
  @override
  Future<void> guardar(String clave, String valor) async =>
      _valores[clave] = valor;
}
