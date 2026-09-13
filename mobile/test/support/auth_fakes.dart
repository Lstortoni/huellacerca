import 'dart:convert';

import 'package:huella_cerca/core/storage/session_storage.dart';

class MemorySessionStorage implements SessionStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

Map<String, Object?> usuarioJson() => {
  'id': 'usuario-1',
  'email': 'prueba@example.com',
  'emailConfirmado': false,
  'mascotero': {
    'id': 'mascotero-1',
    'nombre': 'Ana',
    'apellido': 'Prueba',
    'telefono': null,
    'localidadId': 'localidad-1',
  },
};
Map<String, Object?> sesionJson({
  String token = 'access-1',
  bool expired = false,
  bool refreshExpired = false,
}) => {
  'accessToken': token,
  'refreshToken': 'refresh-$token',
  'expiresAtUtc': DateTime.now()
      .toUtc()
      .add(Duration(minutes: expired ? -1 : 15))
      .toIso8601String(),
  'refreshExpiresAtUtc': DateTime.now()
      .toUtc()
      .add(Duration(days: refreshExpired ? -1 : 30))
      .toIso8601String(),
  'usuario': usuarioJson(),
};
String sesionTexto({bool expired = false, bool refreshExpired = false}) =>
    jsonEncode(sesionJson(expired: expired, refreshExpired: refreshExpired));
