import 'package:flutter/foundation.dart';
import 'package:huella_cerca/models/notificacion_dto.dart';
import 'package:huella_cerca/models/pagina_dto.dart';
import 'package:huella_cerca/services/contracts/notificacion_service.dart';

/// Resumen de aviso con la forma que devuelve la API.
Map<String, dynamic> resumenJson({
  String id = 'publicacion-1',
  int tipo = 1,
  String? nombre = 'Toby',
  int estado = 1,
}) => {
  'id': id,
  'tipoPublicacion': tipo,
  'tipoMascota': 1,
  'nombreMascota': nombre,
  'localidad': 'La Plata',
  'estado': estado,
  'fotoUrl': null,
};

Map<String, dynamic> notificacionJson({
  String id = 'n1',
  bool leida = false,
  int estadoCoincidente = 1,
}) => {
  'id': id,
  'publicacionId': 'publicacion-1',
  'publicacionCoincidenteId': 'publicacion-2',
  'titulo': 'Nueva posible coincidencia',
  'mensaje': 'Hay una publicación que podría coincidir con tu aviso.',
  'fechaCreacion': '2026-09-24T20:30:00Z',
  'fechaLectura': leida ? '2026-09-24T21:00:00Z' : null,
  'publicacion': resumenJson(),
  'coincidente': resumenJson(
    id: 'publicacion-2',
    tipo: 2,
    nombre: null,
    estado: estadoCoincidente,
  ),
};

/// Doble sin HTTP ni temporizador: registra las llamadas de la página.
class NotificacionServiceMock extends ChangeNotifier
    implements NotificacionService {
  int _noLeidas = 0;
  List<NotificacionDto> items = [];
  final leidas = <String>[];
  final consultas = <bool>[]; // soloNoLeidas de cada listado.
  int todas = 0, actualizaciones = 0;

  @override
  int get noLeidas => _noLeidas;
  set noLeidas(int valor) {
    _noLeidas = valor;
    notifyListeners();
  }

  @override
  Future<void> actualizar() async => actualizaciones++;
  @override
  Future<PaginaDto<NotificacionDto>> listar({
    int pagina = 1,
    bool soloNoLeidas = false,
  }) async {
    consultas.add(soloNoLeidas);
    final lista = soloNoLeidas ? items.where((n) => !n.leida).toList() : items;
    return PaginaDto(lista, lista.length, pagina, 20);
  }

  @override
  Future<void> marcarLeida(NotificacionDto notificacion) async =>
      leidas.add(notificacion.id);
  @override
  Future<void> marcarTodas() async {
    todas++;
    noLeidas = 0;
  }

  @override
  void pausar() {}
  @override
  void reanudar() {}
}
