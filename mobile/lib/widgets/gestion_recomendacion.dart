import 'package:flutter/material.dart';

import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import 'contenido_formulario.dart';

/// Comparte el estado de la recomendación en resultados y ficha del prestador.
class GestionRecomendacion extends StatelessWidget {
  const GestionRecomendacion({
    super.key,
    required this.prestadorId,
    required this.auth,
    required this.service,
    required this.onChanged,
    this.compacto = false,
    this.onEditar,
  });
  final String prestadorId;
  final AuthService auth;
  final RecomendacionService service;
  final Future<void> Function() onChanged;
  final bool compacto;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) {
      if (auth.restaurando || auth.ocupado) {
        return const LinearProgressIndicator();
      }
      if (!auth.autenticado) {
        return TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/login'),
          child: const Text('Ingresá para recomendar'),
        );
      }
      return _MiRecomendacion(
        key: ValueKey('${auth.usuario!.id}:$prestadorId'),
        prestadorId: prestadorId,
        service: service,
        compacto: compacto,
        onChanged: onChanged,
        onEditar: onEditar,
      );
    },
  );
}

class _MiRecomendacion extends StatefulWidget {
  const _MiRecomendacion({
    super.key,
    required this.prestadorId,
    required this.service,
    required this.compacto,
    required this.onChanged,
    this.onEditar,
  });
  final String prestadorId;
  final RecomendacionService service;
  final bool compacto;
  final Future<void> Function() onChanged;
  final VoidCallback? onEditar;
  @override
  State<_MiRecomendacion> createState() => _MiRecomendacionState();
}

class _MiRecomendacionState extends State<_MiRecomendacion> {
  RecomendacionDto? _recomendacion;
  Future<List<AspectoDto>>? _catalogo;
  Set<String> _seleccion = {};
  bool _cargando = true, _ocupado = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _asignar(RecomendacionDto? r) {
    _recomendacion = r;
    _seleccion = r?.aspectos.map((a) => a.id).toSet() ?? {};
    if (r != null && !widget.compacto) _catalogo ??= _cargarCatalogo();
  }

  Future<List<AspectoDto>> _cargarCatalogo() {
    final future = widget.service.aspectos();
    // Puede fallar antes del próximo frame. FutureBuilder mostrará ese error;
    // este observador evita que mientras tanto sea una excepción sin manejar.
    future.ignore();
    return future;
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final r = await widget.service.miRecomendacion(widget.prestadorId);
      if (mounted) setState(() => _asignar(r));
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiar(
    Future<RecomendacionDto?> Function() accion,
    String aviso,
  ) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final r = await accion();
      if (!mounted) return;
      setState(() => _asignar(r));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(aviso)));
      await widget.onChanged();
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _retirar() async {
    final aceptar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Retirar tu recomendación?'),
        content: const Text('También se quitarán los aspectos que destacaste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (!mounted || aceptar != true) return;
    await _cambiar(() async {
      await widget.service.retirar(_recomendacion!.id);
      return null;
    }, 'Retiraste tu recomendación.');
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const LinearProgressIndicator();
    // Una consulta fallida no significa que el usuario todavía no recomienda.
    if (_error != null && _recomendacion == null) {
      return Column(
        children: [
          Text(_error!),
          TextButton(
            onPressed: _ocupado ? null : _cargar,
            child: const Text('Revisar mi recomendación'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_recomendacion == null)
          FilledButton(
            onPressed: _ocupado
                ? null
                : () => _cambiar(
                    () => widget.service.crear(
                      CrearRecomendacionRequest(
                        prestadorServicioId: widget.prestadorId,
                      ),
                    ),
                    'Tu recomendación ya está guardada. Los aspectos son opcionales.',
                  ),
            child: Text(_ocupado ? 'Guardando…' : 'Recomendar'),
          )
        else ...[
          const Text('Ya lo recomendás'),
          if (widget.compacto)
            TextButton(
              onPressed: _ocupado ? null : widget.onEditar,
              child: const Text('Modificar aspectos'),
            )
          else ...[
            const Text(
              'Podés destacar aspectos positivos (opcional). Tu recomendación cuenta aunque no elijas ninguno.',
            ),
            FutureBuilder<List<AspectoDto>>(
              future: _catalogo,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => setState(() {
                            _catalogo = _cargarCatalogo();
                          }),
                    child: const Text('No pudimos cargar aspectos. Reintentar'),
                  );
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final opciones = {
                  for (final a in snapshot.data!.where((a) => a.activo))
                    a.id: a,
                  for (final a in _recomendacion!.aspectos) a.id: a,
                };
                return Column(
                  children: [
                    for (final a in opciones.values)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.nombre),
                        subtitle: a.activo
                            ? null
                            : const Text('Aspecto retirado del catálogo'),
                        value: _seleccion.contains(a.id),
                        onChanged: _ocupado
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  _seleccion.add(a.id);
                                } else {
                                  _seleccion.remove(a.id);
                                }
                              }),
                      ),
                    FilledButton(
                      onPressed: _ocupado
                          ? null
                          : () => _cambiar(
                              () => widget.service.guardarAspectos(
                                _recomendacion!.id,
                                _seleccion.toList(),
                              ),
                              'Aspectos guardados.',
                            ),
                      child: const Text('Guardar aspectos'),
                    ),
                  ],
                );
              },
            ),
            TextButton(
              onPressed: _ocupado ? null : _retirar,
              child: const Text('Retirar recomendación'),
            ),
          ],
        ],
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
