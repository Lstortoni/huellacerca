import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/aviso_push.dart';
import '../contracts/auth_service.dart';
import '../contracts/mensajeria_push.dart';
import '../contracts/push_service.dart';

/// Sincroniza una instalación con la cuenta activa. Firebase queda detrás del contrato.
class PushServiceApi implements PushService {
  PushServiceApi(this._auth, this._mensajeria);
  final AuthService _auth;
  final MensajeriaPush _mensajeria;
  final _recibidos = StreamController<AvisoPush>.broadcast();
  final _abiertos = StreamController<AvisoPush>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _reintento;
  Future<void>? _sincronizando;
  bool _iniciado = false, _disposed = false, _cerrando = false;
  String? _cuenta;
  Object? _identidad;
  String? _registrado;
  bool _repetir = false;

  @override
  Stream<AvisoPush> get recibidos => _recibidos.stream;
  @override
  Stream<AvisoPush> get abiertos => _abiertos.stream;

  @override
  Future<void> iniciar() async {
    if (_iniciado || _disposed) return;
    _iniciado = true;
    _auth.addListener(_sesionCambio);
    _subscriptions.add(
      _mensajeria.cambiosToken.listen((_) {
        _registrado = null;
        unawaited(sincronizar());
      }, onError: (Object _) => _programarReintento()),
    );
    _subscriptions.add(
      _mensajeria.recibidos.listen((aviso) {
        if (!_disposed &&
            !_cerrando &&
            aviso.mascoteroId == _auth.usuario?.mascotero.id) {
          _recibidos.add(aviso);
        }
      }),
    );
    _subscriptions.add(
      _mensajeria.abiertos.listen((aviso) {
        if (!_disposed) _abiertos.add(aviso);
      }),
    );
    _sesionCambio();
    try {
      final inicial = await _mensajeria.mensajeInicial();
      if (!_disposed && inicial != null) _abiertos.add(inicial);
    } catch (_) {
      debugPrint('Push: no se pudo recuperar la apertura inicial.');
    }
  }

  void _sesionCambio() {
    if (_disposed || _auth.restaurando || _auth.ocupado) return;
    final cuenta = _auth.usuario?.mascotero.id;
    if (cuenta != _cuenta || !identical(_identidad, _auth.usuario)) {
      _cuenta = cuenta;
      _identidad = _auth.usuario;
      _registrado = null;
      _cerrando = false;
      unawaited(sincronizar());
    }
  }

  @override
  Future<void> sincronizar() async {
    if (_disposed || _cerrando) return;
    if (_sincronizando != null) {
      _repetir = true;
      return _sincronizando;
    }
    _reintento?.cancel();
    final tarea = _sincronizar();
    _sincronizando = tarea;
    try {
      await tarea;
    } finally {
      _sincronizando = null;
      if (_repetir && !_disposed && !_cerrando) {
        _repetir = false;
        unawaited(sincronizar());
      }
    }
  }

  Future<void> _sincronizar() async {
    if (_auth.restaurando || _auth.ocupado) return;
    final cuenta = _auth.usuario?.mascotero.id;
    bool vigente() =>
        !_disposed && !_cerrando && cuenta == _auth.usuario?.mascotero.id;
    try {
      if (cuenta == null) {
        await _mensajeria.borrarToken();
        return;
      }
      final id = await _mensajeria.instalacionId();
      final permiso = await _mensajeria.permiso(solicitar: true);
      if (!vigente()) return;
      if (!permiso) {
        await _auth.deleteProtegido('api/dispositivos-push/$id');
        _registrado = null;
        return;
      }
      final token = await _mensajeria.token();
      if (!vigente()) return;
      if (token == null) {
        _programarReintento();
        return;
      }
      final registro = '$cuenta:$token';
      if (_registrado == registro) return;
      await _auth.putProtegido('api/dispositivos-push/$id', {
        'token': token,
        'plataforma': 'android',
      });
      if (vigente()) _registrado = registro;
    } catch (_) {
      debugPrint(
        'Push: no se pudo sincronizar el dispositivo; se reintentará.',
      );
      _programarReintento();
    }
  }

  void _programarReintento() {
    if (_disposed || _cerrando) return;
    _reintento?.cancel();
    _reintento = Timer(
      const Duration(minutes: 1),
      () => unawaited(sincronizar()),
    );
  }

  @override
  Future<void> desvincular() async {
    _cerrando = true;
    _reintento?.cancel();
    // Esperar el PUT evita que termine después del DELETE y reactive el dispositivo.
    await _sincronizando;
    try {
      final id = await _mensajeria.instalacionId();
      if (_auth.autenticado) {
        await _auth.deleteProtegido('api/dispositivos-push/$id');
      }
    } finally {
      _registrado = null;
      await _mensajeria.borrarToken();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_sesionCambio);
    _reintento?.cancel();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    unawaited(_recibidos.close());
    unawaited(_abiertos.close());
  }
}
