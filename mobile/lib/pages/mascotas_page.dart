import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/grilla.dart';
import '../widgets/lista_paginada.dart';
import '../widgets/opcion_tipo_aviso.dart';
import '../widgets/selector_opciones.dart';
import '../widgets/tarjeta_publicacion.dart';
import 'publicacion_detalle_page.dart';

/// Búsqueda de avisos. Tipo y especie se aplican al tocarlos; el resto de los
/// filtros está en un panel que se aplica al cerrarlo.
class MascotasPage extends StatefulWidget {
  const MascotasPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
    this.soloMias = false,
  });
  final AuthService auth;
  final PublicacionService service;
  final UbicacionService ubicacion;
  final bool soloMias;
  @override
  State<MascotasPage> createState() => _MascotasPageState();
}

class _MascotasPageState extends State<MascotasPage> {
  final _zona = TextEditingController();
  int? _tipo, _mascota;
  late final int? _estadoInicial = widget.soloMias ? null : 1;
  late int? _estado = _estadoInicial;
  String? _provincia, _localidad, _lugar;
  int _revisionUbicacion = 0;
  DateTime? _desde, _hasta;
  late bool _mias = widget.soloMias;
  String? _error;
  int _revision = 0;
  bool _panelAbierto = false;
  late Map<String, String> _filtros = widget.soloMias
      ? {'mascoteroId': widget.auth.usuario!.mascotero.id}
      : {'estado': '1'};
  Future<List<CaracteristicaMascotaDto>>? _opciones;
  final Map<String, int> _caracteristicas = {};
  final Map<String, String> _nombresCaracteristicas = {};

  void _cambiarMascota(int? tipo) {
    _mascota = tipo;
    _caracteristicas.clear();
    _opciones = tipo == null ? null : widget.service.caracteristicas(tipo);
    _opciones?.ignore();
  }

  @override
  void dispose() {
    _zona.dispose();
    super.dispose();
  }

  void _buscar() {
    if (_desde != null && _hasta != null && _desde!.isAfter(_hasta!)) {
      setState(() {
        _error = 'La fecha desde no puede superar la fecha hasta.';
        _panelAbierto = true;
      });
      return;
    }
    setState(() {
      _error = null;
      _panelAbierto = false;
      _filtros = {
        for (final c in _caracteristicas.entries) c.key: '${c.value}',
        if (_tipo != null) 'tipoPublicacion': '$_tipo',
        if (_mascota != null) 'tipoMascota': '$_mascota',
        if (_estado != null) 'estado': '$_estado',
        'provinciaId': ?_provincia,
        'localidadId': ?_localidad,
        if (_zona.text.trim().isNotEmpty) 'zona': _zona.text.trim(),
        if (_desde != null) 'fechaDesde': fechaApi(_desde!),
        if (_hasta != null) 'fechaHasta': fechaApi(_hasta!),
        if (_mias && widget.auth.autenticado)
          'mascoteroId': widget.auth.usuario!.mascotero.id,
      };
      _revision++;
    });
  }

  void _quitarUbicacion() {
    _provincia = _localidad = _lugar = null;
    _revisionUbicacion++;
  }

  void _limpiarPanel() => setState(() {
    _estado = _estadoInicial;
    _quitarUbicacion();
    _zona.clear();
    _desde = _hasta = null;
    _caracteristicas.clear();
    _mias = widget.soloMias;
    _error = null;
  });

  /// Filtros del panel que difieren del valor inicial, con su acción para quitarlos.
  List<(String, VoidCallback)> get _activos => [
    if (_estado != _estadoInicial)
      (
        switch (_estado) {
          1 => 'Activas',
          2 => 'Resueltas',
          _ => 'Activas y resueltas',
        },
        () => _estado = _estadoInicial,
      ),
    if (_provincia != null) (_lugar ?? 'Ubicación', _quitarUbicacion),
    if (_zona.text.trim().isNotEmpty)
      ('Zona: ${_zona.text.trim()}', _zona.clear),
    if (_desde != null) ('Desde ${fechaVisible(_desde!)}', () => _desde = null),
    if (_hasta != null) ('Hasta ${fechaVisible(_hasta!)}', () => _hasta = null),
    for (final campo in _caracteristicas.keys.toList())
      (
        _nombresCaracteristicas[campo] ?? campo,
        () => _caracteristicas.remove(campo),
      ),
    if (_mias && !widget.soloMias)
      ('Solo mis publicaciones', () => _mias = false),
  ];

  Future<void> _fecha(bool desde) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (desde ? _desde : _hasta) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (mounted && value != null) {
      setState(() {
        if (desde) {
          _desde = value;
        } else {
          _hasta = value;
        }
      });
    }
  }

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  /// Grilla 2×2 de tipos, todos del mismo ancho. Sin selección se ven todos;
  /// tocar el tipo elegido lo quita.
  Widget _filaTipos() => Grilla(
    columnas: 2,
    children: [
      for (final t in tiposPublicacionBusqueda.entries)
        OpcionTipoAviso(
          tipo: t.key,
          texto: t.value,
          seleccionado: _tipo == t.key,
          onTap: () {
            _tipo = _tipo == t.key ? null : t.key;
            _buscar();
          },
        ),
    ],
  );

  /// Especie como selector segmentado; admite quedar sin selección (todas).
  Widget _selectorMascota() => SegmentedButton<int>(
    emptySelectionAllowed: true,
    showSelectedIcon: false,
    segments: [
      for (final m in tiposMascota.entries)
        ButtonSegment(
          value: m.key,
          icon: Text(
            iconosMascota[m.key]!,
            style: const TextStyle(fontSize: 18),
          ),
          label: Text(m.value),
        ),
    ],
    selected: {?_mascota},
    onSelectionChanged: (s) {
      _cambiarMascota(s.firstOrNull);
      _buscar();
    },
  );

  Widget _botonFiltros() {
    final cantidad = _activos.length;
    return FilledButton.tonalIcon(
      onPressed: _panelAbierto
          ? _buscar
          : () => setState(() => _panelAbierto = true),
      icon: Badge(
        isLabelVisible: cantidad > 0,
        label: Text('$cantidad'),
        child: Icon(
          _panelAbierto ? Icons.expand_less_rounded : Icons.tune_rounded,
        ),
      ),
      label: const Text('Filtros'),
    );
  }

  Widget _caracteristicasPanel() {
    if (_mascota == null) {
      return const Text(
        'Elegí Perro, Gato u Otro para filtrar por sus características.',
      );
    }
    return FutureBuilder<List<CaracteristicaMascotaDto>>(
      future: _opciones,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(() => _cambiarMascota(_mascota)),
            child: const Text('No pudimos cargar los filtros. Reintentar'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cada filtro busca el valor exacto; los avisos sin ese dato quedan fuera.',
            ),
            for (final campo in snapshot.data!) ...[
              const SizedBox(height: 10),
              Text(campo.nombre),
              const SizedBox(height: 6),
              SelectorOpciones(
                opciones: [
                  for (final o in campo.opciones)
                    OpcionSelector(o.id, o.nombre),
                ],
                seleccion: _caracteristicas[campo.campo],
                onChanged: (v) => setState(() {
                  if (v == null) {
                    _caracteristicas.remove(campo.campo);
                  } else {
                    _caracteristicas[campo.campo] = v;
                    _nombresCaracteristicas[campo.campo] = campo.opciones
                        .firstWhere((o) => o.id == v)
                        .nombre;
                  }
                }),
              ),
            ],
            if (_caracteristicas.isNotEmpty)
              TextButton(
                onPressed: () => setState(_caracteristicas.clear),
                child: const Text('Quitar filtros de características'),
              ),
          ],
        );
      },
    );
  }

  Widget _panel() {
    final theme = Theme.of(context);
    // Material (no Container) para que SwitchListTile pinte sobre este fondo.
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _contenidoPanel(theme),
        ),
      ),
    );
  }

  Widget _contenidoPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo('Estado'),
        // 0 representa "Todas" solo en el selector; el filtro usa null.
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 1, label: Text('Activas')),
            ButtonSegment(value: 2, label: Text('Resueltas')),
            ButtonSegment(value: 0, label: Text('Todas')),
          ],
          selected: {_estado ?? 0},
          onSelectionChanged: (s) =>
              setState(() => _estado = s.first == 0 ? null : s.first),
        ),
        _titulo('Ubicación'),
        CampoUbicacion(
          key: ValueKey(_revisionUbicacion),
          service: widget.ubicacion,
          onChanged: (p, l) {
            _provincia = p;
            _localidad = l;
          },
          onDescripcion: (d) => _lugar = d,
        ),
        TextField(
          controller: _zona,
          maxLength: 250,
          decoration: const InputDecoration(labelText: 'Zona', counterText: ''),
        ),
        _titulo('Características'),
        _caracteristicasPanel(),
        _titulo('Fechas'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _fecha(true),
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _desde == null ? 'Desde' : 'Desde: ${fechaVisible(_desde!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _fecha(false),
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _hasta == null ? 'Hasta' : 'Hasta: ${fechaVisible(_hasta!)}',
              ),
            ),
            if (_desde != null || _hasta != null)
              TextButton(
                onPressed: () => setState(() => _desde = _hasta = null),
                child: const Text('Quitar fechas'),
              ),
          ],
        ),
        if (!widget.soloMias)
          ListenableBuilder(
            listenable: widget.auth,
            builder: (_, _) => widget.auth.autenticado
                ? SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Solo mis publicaciones'),
                    value: _mias,
                    onChanged: (v) => setState(() => _mias = v),
                  )
                : const SizedBox.shrink(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(onPressed: _limpiarPanel, child: const Text('Limpiar')),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _buscar,
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activos = _activos;
    return Scaffold(
      appBar: BarraSuperior(
        auth: widget.auth,
        titulo: widget.soloMias ? 'Mis publicaciones' : 'Buscar mascotas',
      ),
      body: ContenidoFormulario(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.soloMias)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tus avisos de mascotas, incluidos los activos y los resueltos.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            _filaTipos(),
            if (_tipo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  explicacionesPublicacion[_tipo]!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            _selectorMascota(),
            const SizedBox(height: 10),
            _botonFiltros(),
            // Con el panel cerrado se ven los filtros aplicados para quitarlos.
            if (!_panelAbierto && activos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (texto, quitar) in activos)
                      InputChip(
                        label: Text(texto),
                        onDeleted: () {
                          setState(quitar);
                          _buscar();
                        },
                        deleteButtonTooltipMessage: 'Quitar filtro',
                      ),
                  ],
                ),
              ),
            Visibility(
              visible: _panelAbierto,
              maintainState: true,
              child: _panel(),
            ),
            const SizedBox(height: 16),
            ListaPaginada<PublicacionDto>(
              key: ValueKey(_revision),
              cargar: (pagina) =>
                  widget.service.buscar(filtros: _filtros, pagina: pagina),
              itemBuilder: (p, recargar) => TarjetaPublicacion(
                publicacion: p,
                service: widget.service,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PublicacionDetallePage(
                        id: p.id,
                        auth: widget.auth,
                        service: widget.service,
                      ),
                    ),
                  );
                  recargar();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
