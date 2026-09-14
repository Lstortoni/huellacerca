/// Permite reemplazar el almacenamiento del dispositivo por memoria en pruebas.
abstract class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}
