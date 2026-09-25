import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/notificacion_dto.dart';
import '../../models/pagina_dto.dart';
import '../contracts/auth_service.dart';
import '../contracts/notificacion_service.dart';

/// Consulta el contador cada [intervalo] mientras hay sesión y la app está en
/// primer plano. Además consulta al iniciar sesión y al volver a la app.
class NotificacionServiceApi extends ChangeNotifier
    implements NotificacionService {
  NotificacionServiceApi(
    this._auth, {
    this.intervalo = const Duration(minutes: 2),
  }) {
    _auth.addListener(_sesionCambio);
    _sesionCambio();
  }
  final AuthService _auth;
  final Duration intervalo;
  Timer? _timer;
  int _noLeidas = 0;
  bool _enPausa = false, _consultando = false;

  bool get _activa => _auth.autenticado && !_auth.restaurando;
  @override
  int get noLeidas => _noLeidas;

  /// La sesión notifica cambios frecuentes (ocupado, aviso): solo arranca o
  /// detiene la consulta cuando corresponde.
  void _sesionCambio() {
    if (_activa && !_enPausa) {
      if (_timer == null) {
        _timer = Timer.periodic(intervalo, (_) => actualizar());
        actualizar();
      }
    } else {
      _detener();
      // Otra cuenta en el mismo teléfono no debe ver el número anterior.
      if (!_auth.autenticado) _asignar(0);
    }
  }

  void _detener() {
    _timer?.cancel();
    _timer = null;
  }

  void _asignar(int valor) {
    if (valor == _noLeidas) return;
    _noLeidas = valor;
    notifyListeners();
  }

  @override
  Future<void> actualizar() async {
    if (!_activa || _consultando) return;
    _consultando = true;
    try {
      final j = await _auth.getProtegido(
        'api/notificaciones/no-leidas/cantidad',
      ) as Map<String, dynamic>;
      if (_activa) _asignar(j['cantidad'] as int);
    } catch (_) {
      // Consulta de fondo: no se muestra error y se conserva el último valor.
    } finally {
      _consultando = false;
    }
  }

  @override
  Future<PaginaDto<NotificacionDto>> listar({
    int pagina = 1,
    bool soloNoLeidas = false,
  }) async => PaginaDto.fromJson(
    await _auth.getProtegido(
      'api/notificaciones?pagina=$pagina&tamanoPagina=20&soloNoLeidas=$soloNoLeidas',
    ) as Map<String, dynamic>,
    NotificacionDto.fromJson,
  );

  @override
  Future<void> marcarLeida(NotificacionDto notificacion) async {
    if (notificacion.leida) return;
    _asignar(_noLeidas > 0 ? _noLeidas - 1 : 0);
    try {
      await _auth.patchProtegido('api/notificaciones/${notificacion.id}/leer');
    } catch (_) {
      // No impide abrir el aviso; se corrige el contador con el valor real.
      await actualizar();
    }
  }

  @override
  Future<void> marcarTodas() async {
    await _auth.patchProtegido('api/notificaciones/leer-todas');
    _asignar(0);
  }

  @override
  void pausar() {
    _enPausa = true;
    _detener();
  }

  @override
  void reanudar() {
    _enPausa = false;
    _sesionCambio();
  }

  @override
  void dispose() {
    _auth.removeListener(_sesionCambio);
    _detener();
    super.dispose();
  }
}
