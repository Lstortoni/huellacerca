import 'package:flutter/material.dart';

import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/gestion_recomendacion.dart';
import 'prestador_detalle_page.dart';

class RecomendarServicioPage extends StatefulWidget {
  const RecomendarServicioPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
  });
  final AuthService auth;
  final RecomendacionService service;
  final UbicacionService ubicacion;
  @override
  State<RecomendarServicioPage> createState() => _RecomendarServicioPageState();
}

class _RecomendarServicioPageState extends State<RecomendarServicioPage> {
  final _buscarForm = GlobalKey<FormState>(),
      _crearForm = GlobalKey<FormState>();
  final _nombre = TextEditingController(),
      _direccion = TextEditingController(),
      _telefono = TextEditingController(),
      _enlace = TextEditingController();
  late Future<List<RubroDto>> _rubros;
  String? _rubro, _localidad, _error;
  List<PrestadorDto>? _similares;
  bool _nuevo = false, _buscando = false, _guardando = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _rubros = widget.service.rubros();
  }

  @override
  void dispose() {
    for (final c in [_nombre, _direccion, _telefono, _enlace]) {
      c.dispose();
    }
    super.dispose();
  }

  void _invalidar() => setState(() {
    _revision++;
    _similares = null;
    _nuevo = false;
    _error = null;
    _buscando = false;
  });
  Future<void> _buscar() async {
    if (_buscando || !_buscarForm.currentState!.validate()) return;
    final revision = ++_revision;
    setState(() {
      _buscando = true;
      _error = null;
      _similares = null;
      _nuevo = false;
    });
    try {
      final items = await widget.service.similares(
        nombre: _nombre.text.trim(),
        rubroId: _rubro!,
        localidadId: _localidad!,
      );
      if (mounted && revision == _revision) setState(() => _similares = items);
    } catch (e) {
      if (mounted && revision == _revision) {
        setState(() => _error = mensajeError(e));
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _buscando = false);
    }
  }

  String? _opcional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  Future<void> _guardar() async {
    if (_guardando || !_crearForm.currentState!.validate() || !_nuevo) {
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final r = await widget.service.crear(
        CrearRecomendacionRequest(
          nuevoPrestador: NuevoPrestadorRequest(
            nombre: _nombre.text.trim(),
            rubroId: _rubro!,
            localidadId: _localidad!,
            direccion: _opcional(_direccion),
            telefono: _opcional(_telefono),
            enlace: _opcional(_enlace),
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PrestadorDetallePage(
            permitirGestion: true,
            id: r.prestador.id,
            auth: widget.auth,
            service: widget.service,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _verPrestador(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PrestadorDetallePage(
          permitirGestion: true,
          id: id,
          auth: widget.auth,
          service: widget.service,
        ),
      ),
    );
    if (mounted) setState(() => _revision++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Recomendar un servicio'),
    body: RequiereSesion(
      auth: widget.auth,
      child: ContenidoFormulario(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Primero buscá si el servicio ya fue recomendado.'),
            Form(
              key: _buscarForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombre,
                    enabled: !_guardando,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servicio o negocio',
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Escribí al menos 2 caracteres.'
                        : null,
                    onChanged: (_) => _invalidar(),
                  ),
                  FutureBuilder<List<RubroDto>>(
                    future: _rubros,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return TextButton(
                          onPressed: () => setState(() {
                            _rubros = widget.service.rubros();
                          }),
                          child: const Text(
                            'No pudimos cargar rubros. Reintentar',
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _rubro,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Rubro'),
                        items: snapshot.data!
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.nombre),
                              ),
                            )
                            .toList(),
                        validator: requerido,
                        onChanged: _guardando
                            ? null
                            : (v) {
                                _rubro = v;
                                _invalidar();
                              },
                      );
                    },
                  ),
                  CampoUbicacion(
                    service: widget.ubicacion,
                    obligatorio: true,
                    enabled: !_guardando,
                    onChanged: (_, l) {
                      _localidad = l;
                      _invalidar();
                    },
                  ),
                  FilledButton(
                    onPressed: _buscando || _guardando ? null : _buscar,
                    child: Text(_buscando ? 'Buscando…' : 'Buscar similares'),
                  ),
                ],
              ),
            ),
            if (_similares != null) ...[
              const SizedBox(height: 16),
              Text(
                _similares!.isEmpty
                    ? 'No encontramos servicios similares.'
                    : 'Encontramos estos servicios. ¿Es alguno de ellos?',
              ),
              ..._similares!.map(
                (p) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          p.nombre,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('${p.rubro} · ${p.localidad}'),
                        if (p.direccion != null) Text(p.direccion!),
                        GestionRecomendacion(
                          key: ValueKey('$_revision:${p.id}'),
                          prestadorId: p.id,
                          auth: widget.auth,
                          service: widget.service,
                          compacto: true,
                          onChanged: () async => _verPrestador(p.id),
                          onEditar: () => _verPrestador(p.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _guardando
                    ? null
                    : () => setState(() {
                        _nuevo = true;
                        _error = null;
                      }),
                child: const Text('Es otro servicio: crear uno nuevo'),
              ),
            ],
            if (_nuevo)
              Form(
                key: _crearForm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Nuevo servicio: ${_nombre.text.trim()}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextFormField(
                      controller: _direccion,
                      enabled: !_guardando,
                      maxLength: 250,
                      decoration: const InputDecoration(
                        labelText: 'Dirección (opcional)',
                      ),
                    ),
                    TextFormField(
                      controller: _telefono,
                      enabled: !_guardando,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                      ),
                    ),
                    TextFormField(
                      controller: _enlace,
                      enabled: !_guardando,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Enlace (opcional)',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final uri = Uri.tryParse(v.trim());
                        return uri != null &&
                                uri.host.isNotEmpty &&
                                (uri.scheme == 'http' || uri.scheme == 'https')
                            ? null
                            : 'Ingresá un enlace http:// o https:// válido.';
                      },
                    ),
                    FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: Text(
                        _guardando ? 'Guardando…' : 'Crear y recomendar',
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}
