import 'dart:async';

import 'package:flutter/material.dart';

import '../models/localidad_dto.dart';
import '../models/provincia_dto.dart';
import '../services/contracts/ubicacion_service.dart';
import 'contenido_formulario.dart';

/// Quita acentos y pasa a minúsculas para comparar nombres de provincias.
String _normalizar(String texto) {
  const con = 'áéíóúüñ';
  const sin = 'aeiouun';
  final minusculas = texto.toLowerCase().trim();
  return String.fromCharCodes(
    minusculas.runes.map((r) {
      final i = con.indexOf(String.fromCharCode(r));
      return i < 0 ? r : sin.codeUnitAt(i);
    }),
  );
}

/// Buscador de localidades en todo el país, en un panel de casi toda la
/// pantalla. Sin texto muestra tu localidad y las recientes; con 2 letras o
/// más filtra mientras escribís y carga más resultados al desplazarse.
/// Con [permitirProvincia] ofrece también provincias enteras (filtros).
class SelectorUbicacion extends StatefulWidget {
  const SelectorUbicacion({
    super.key,
    required this.ubicacion,
    this.permitirProvincia = false,
    this.localidadPerfilId,
  });
  final UbicacionService ubicacion;
  final bool permitirProvincia;
  final String? localidadPerfilId;

  static Future<UbicacionElegida?> mostrar(
    BuildContext context, {
    required UbicacionService ubicacion,
    bool permitirProvincia = false,
    String? localidadPerfilId,
  }) => showModalBottomSheet<UbicacionElegida>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: SelectorUbicacion(
        ubicacion: ubicacion,
        permitirProvincia: permitirProvincia,
        localidadPerfilId: localidadPerfilId,
      ),
    ),
  );

  @override
  State<SelectorUbicacion> createState() => _SelectorUbicacionState();
}

class _SelectorUbicacionState extends State<SelectorUbicacion> {
  final _texto = TextEditingController();
  final _scroll = ScrollController();
  Timer? _espera;
  String _busqueda = '';
  List<LocalidadDto> _resultados = [];
  int _pagina = 0, _total = 0, _solicitud = 0;
  bool _cargando = false;
  String? _error;
  List<LocalidadDto> _recientes = [];
  LocalidadDto? _perfil;
  List<ProvinciaDto> _provincias = [];

  bool get _buscando => _busqueda.length >= 2;
  bool get _hayMas => _resultados.length < _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
    widget.ubicacion.recientes().then((r) {
      if (mounted) setState(() => _recientes = r);
    });
    if (widget.localidadPerfilId case final id?) {
      widget.ubicacion.getLocalidad(id).then((l) {
        if (mounted) setState(() => _perfil = l);
      }, onError: (Object _) {}); // Sin la sugerencia se puede buscar igual.
    }
    if (widget.permitirProvincia) {
      widget.ubicacion.getProvincias().then((p) {
        if (mounted) setState(() => _provincias = p);
      }, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Espera a que se deje de escribir para no consultar por cada letra.
  void _alEscribir(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 300), () {
      _busqueda = _texto.text.trim();
      if (_buscando) {
        _cargar(reiniciar: true);
      } else {
        setState(() {
          _solicitud++;
          _resultados = [];
          _error = null;
          _cargando = false;
        });
      }
    });
  }

  void _alDesplazar() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200 &&
        !_cargando &&
        _error == null &&
        _hayMas) {
      _cargar();
    }
  }

  Future<void> _cargar({bool reiniciar = false}) async {
    final solicitud = ++_solicitud;
    final pagina = reiniciar ? 1 : _pagina + 1;
    setState(() {
      _cargando = true;
      _error = null;
      if (reiniciar) _resultados = [];
    });
    try {
      final r = await widget.ubicacion.getLocalidades(
        busqueda: _busqueda,
        pagina: pagina,
      );
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _resultados = [..._resultados, ...r.items];
        _total = r.total;
        _pagina = pagina;
      });
    } catch (e) {
      if (mounted && solicitud == _solicitud) {
        setState(() => _error = mensajeError(e));
      }
    } finally {
      if (mounted && solicitud == _solicitud) setState(() => _cargando = false);
    }
  }

  void _elegir(UbicacionElegida ubicacion) =>
      Navigator.of(context).pop(ubicacion);

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _localidad(LocalidadDto l, IconData icono) => ListTile(
    leading: Icon(icono),
    title: Text(l.nombre),
    subtitle: l.provincia.isEmpty ? null : Text(l.provincia),
    onTap: () => _elegir(UbicacionElegida.localidad(l)),
  );

  List<Widget> _sugerencias() => [
    if (_perfil case final perfil?) ...[
      _titulo('Tu localidad'),
      _localidad(perfil, Icons.home_rounded),
    ],
    if (_recientes.isNotEmpty) ...[
      _titulo('Recientes'),
      for (final l in _recientes) _localidad(l, Icons.history_rounded),
    ],
    Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.permitirProvincia
            ? 'Escribí al menos 2 letras del nombre de una localidad o provincia.'
            : 'Escribí al menos 2 letras del nombre de tu localidad.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  ];

  List<Widget> _encontrados() {
    final buscado = _normalizar(_busqueda);
    final provincias = widget.permitirProvincia
        ? _provincias.where((p) => _normalizar(p.nombre).contains(buscado))
        : const <ProvinciaDto>[];
    return [
      if (provincias.isNotEmpty) ...[
        _titulo('Provincias'),
        for (final p in provincias)
          ListTile(
            leading: const Icon(Icons.map_rounded),
            title: Text(p.nombre),
            subtitle: const Text('Toda la provincia'),
            onTap: () => _elegir(UbicacionElegida.provincia(p.id, p.nombre)),
          ),
        _titulo('Localidades'),
      ],
      for (final l in _resultados) _localidad(l, Icons.location_on_outlined),
      if (_cargando)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_error != null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _cargar(reiniciar: _resultados.isEmpty),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        )
      else if (_resultados.isEmpty && provincias.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No encontramos localidades con «$_busqueda».',
            textAlign: TextAlign.center,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      children: [
        TextField(
          controller: _texto,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (texto) {
            _alEscribir(texto);
            setState(() {}); // Muestra u oculta la ✕.
          },
          decoration: InputDecoration(
            hintText: widget.permitirProvincia
                ? 'Buscá una localidad o provincia'
                : 'Buscá tu localidad',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _texto.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _texto.clear();
                      _alEscribir('');
                      setState(() {});
                    },
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: _buscando ? _encontrados() : _sugerencias(),
          ),
        ),
      ],
    ),
  );
}
