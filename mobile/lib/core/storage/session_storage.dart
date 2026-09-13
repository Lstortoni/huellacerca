import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Permite reemplazar el almacenamiento del dispositivo por memoria en pruebas.
abstract class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({this.key = 'huella_cerca_session'});
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String key;
  @override
  Future<String?> read() => _storage.read(key: key);
  @override
  Future<void> write(String value) => _storage.write(key: key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: key);
}
