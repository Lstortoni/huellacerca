import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../core/theme/tema_servicios.dart';
import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/gestion_recomendacion.dart';
import '../widgets/grilla.dart';
import '../widgets/opcion_tipo_aviso.dart';
import '../widgets/seccion_formulario.dart';
import '../widgets/tarjeta_prestador.dart';
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

  Widget _encabezado(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColoresApp.ambar, Color(0xFFB57A12)],
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          child: const Icon(Icons.recommend_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compartí una buena experiencia',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Primero buscá si el servicio ya fue recomendado.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _campoRubro(ThemeData theme) => FutureBuilder<List<RubroDto>>(
    future: _rubros,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(() {
            _rubros = widget.service.rubros();
          }),
          child: const Text('No pudimos cargar rubros. Reintentar'),
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      return FormField<String>(
        validator: (_) => _rubro == null ? 'Elegí un rubro.' : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rubro', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Grilla(
              columnas: 3,
              children: [
                for (final r in snapshot.data!)
                  OpcionIcono(
                    icono: iconoRubro(r.nombre),
                    texto: r.nombre,
                    color: ColoresApp.ambar,
                    fondo: ColoresApp.ambarSuave,
                    vertical: true,
                    seleccionado: _rubro == r.id,
                    onTap: _guardando
                        ? null
                        : () {
                            _rubro = r.id;
                            field.didChange(r.id);
                            _invalidar();
                          },
                  ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  field.errorText!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _similaresEncontrados(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          _similares!.isEmpty
              ? 'No encontramos servicios similares.'
              : 'Encontramos estos servicios. ¿Es alguno de ellos?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      for (final p in _similares!)
        TarjetaPrestador(
          prestador: p,
          pie: GestionRecomendacion(
            key: ValueKey('$_revision:${p.id}'),
            prestadorId: p.id,
            auth: widget.auth,
            service: widget.service,
            compacto: true,
            onChanged: () async => _verPrestador(p.id),
            onEditar: () => _verPrestador(p.id),
          ),
        ),
      OutlinedButton.icon(
        onPressed: _guardando
            ? null
            : () => setState(() {
                _nuevo = true;
                _error = null;
              }),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Es otro servicio: crear uno nuevo'),
      ),
    ],
  );

  Widget _formularioNuevo(ThemeData theme) => Form(
    key: _crearForm,
    child: SeccionFormulario(
      titulo: 'Nuevo servicio: ${_nombre.text.trim()}',
      subtitulo: 'Estos datos son opcionales y se muestran en la ficha.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TextFormField(
            controller: _direccion,
            enabled: !_guardando,
            maxLength: 250,
            decoration: const InputDecoration(
              labelText: 'Dirección (opcional)',
              prefixIcon: Icon(Icons.location_on_rounded),
              counterText: '',
            ),
          ),
          TextFormField(
            controller: _telefono,
            enabled: !_guardando,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Teléfono (opcional)',
              prefixIcon: Icon(Icons.call_rounded),
              counterText: '',
            ),
          ),
          TextFormField(
            controller: _enlace,
            enabled: !_guardando,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Enlace (opcional)',
              prefixIcon: Icon(Icons.link_rounded),
              counterText: '',
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
          FilledButton.icon(
            style: ColoresApp.accionPrincipal,
            onPressed: _guardando ? null : _guardar,
            icon: const Icon(Icons.thumb_up_rounded),
            label: Text(_guardando ? 'Guardando…' : 'Crear y recomendar'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => TemaServicios(
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: BarraSuperior(
            auth: widget.auth,
            titulo: 'Recomendar un servicio',
          ),
          body: RequiereSesion(
            auth: widget.auth,
            child: ContenidoFormulario(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _encabezado(theme),
                  Form(
                    key: _buscarForm,
                    child: SeccionFormulario(
                      titulo: '¿Qué servicio querés recomendar?',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nombre,
                            enabled: !_guardando,
                            maxLength: 150,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del servicio o negocio',
                              prefixIcon: Icon(Icons.storefront_rounded),
                              counterText: '',
                            ),
                            validator: (v) => (v?.trim().length ?? 0) < 2
                                ? 'Escribí al menos 2 caracteres.'
                                : null,
                            onChanged: (_) => _invalidar(),
                          ),
                          const SizedBox(height: 14),
                          _campoRubro(theme),
                          const SizedBox(height: 14),
                          CampoUbicacion(
                            service: widget.ubicacion,
                            obligatorio: true,
                            enabled: !_guardando,
                            onChanged: (_, l) {
                              _localidad = l;
                              _invalidar();
                            },
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _buscando || _guardando ? null : _buscar,
                            icon: const Icon(Icons.search_rounded),
                            label: Text(
                              _buscando ? 'Buscando…' : 'Buscar similares',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_similares != null) _similaresEncontrados(theme),
                  if (_nuevo) ...[
                    const SizedBox(height: 14),
                    _formularioNuevo(theme),
                  ],
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
