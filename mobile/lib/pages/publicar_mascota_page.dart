import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../models/foto_seleccionada.dart';
import '../models/publicacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/grilla.dart';
import '../widgets/muestra_color.dart';
import '../widgets/opcion_tipo_aviso.dart';
import '../widgets/seccion_formulario.dart';
import '../widgets/selector_opciones.dart';
import 'publicacion_detalle_page.dart';

/// Formulario en secciones. El tipo de aviso decide qué campos se piden:
/// Busco adoptar no usa nombre ni fecha; las adopciones no usan fecha.
class PublicarMascotaPage extends StatefulWidget {
  const PublicarMascotaPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
  });
  final AuthService auth;
  final PublicacionService service;
  final UbicacionService ubicacion;
  @override
  State<PublicarMascotaPage> createState() => _PublicarMascotaPageState();
}

class _PublicarMascotaPageState extends State<PublicarMascotaPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController(),
      _descripcion = TextEditingController(),
      _zona = TextEditingController(),
      _contacto = TextEditingController();
  int _tipo = 1, _mascota = 1;
  String? _localidad, _error;
  DateTime? _fecha;
  bool _ocupado = false;
  bool _eligiendoFoto = false;
  FotoSeleccionada? _foto;
  String? _errorFoto;
  Future<void> _elegirFoto({bool recuperar = false}) async {
    if (_ocupado || _eligiendoFoto) return;
    setState(() {
      _eligiendoFoto = true;
      _errorFoto = null;
    });
    try {
      final foto = recuperar
          ? await widget.service.recuperarFoto()
          : await widget.service.elegirFoto();
      if (mounted && foto != null) setState(() => _foto = foto);
    } catch (e) {
      if (mounted) setState(() => _errorFoto = mensajeError(e));
    } finally {
      if (mounted) setState(() => _eligiendoFoto = false);
    }
  }

  late Future<List<CaracteristicaMascotaDto>> _opciones;
  final Map<String, int> _caracteristicas = {};
  @override
  void initState() {
    super.initState();
    _opciones = _cargarOpciones();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _elegirFoto(recuperar: true);
    });
  }

  Future<List<CaracteristicaMascotaDto>> _cargarOpciones() {
    final future = widget.service.caracteristicas(_mascota);
    // FutureBuilder muestra el error; observarlo también antes del próximo frame.
    future.ignore();
    return future;
  }

  void _cambiarMascota(int tipo) {
    setState(() {
      _mascota = tipo;
      _caracteristicas.clear();
      _opciones = _cargarOpciones();
    });
  }

  @override
  void dispose() {
    for (final c in [_nombre, _descripcion, _zona, _contacto]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_ocupado || _eligiendoFoto) return;
    if (!_form.currentState!.validate()) {
      // El botón está fijo abajo: avisar aunque el campo con error no se vea.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisá los campos marcados en rojo.')),
      );
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final p = await widget.service.crear(
        CrearPublicacionRequest(
          tipoPublicacion: _tipo,
          tipoMascota: _mascota,
          nombreMascota: _tipo == 4 || _nombre.text.trim().isEmpty
              ? null
              : _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          fechaSuceso: _tipo <= 2 ? _fecha : null,
          localidadId: _localidad!,
          zona: _zona.text.trim(),
          informacionContacto: _contacto.text.trim(),
          tamano: _caracteristicas['tamano'],
          raza: _caracteristicas['raza'],
          pelaje: _caracteristicas['pelaje'],
          colorPredominante: _caracteristicas['colorPredominante'],
          colorOjos: _caracteristicas['colorOjos'],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PublicacionDetallePage(
            id: p.id,
            auth: widget.auth,
            service: widget.service,
            fotoPendiente: _foto,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Widget _encabezado(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColoresApp.verde, ColoresApp.verdeClaro],
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          child: const Icon(Icons.campaign_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contale a la comunidad',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Cuantos más datos, más fácil es ayudar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _seccionTipo() => SeccionFormulario(
    titulo: '¿Qué querés publicar?',
    child: KeyedSubtree(
      key: const ValueKey('campo:¿Qué querés publicar?'),
      child: Grilla(
        columnas: 2,
        children: [
          for (final t in tiposPublicacion.entries)
            OpcionTipoAviso(
              tipo: t.key,
              texto: t.value,
              vertical: true,
              seleccionado: _tipo == t.key,
              onTap: _ocupado
                  ? null
                  : () => setState(() {
                      _tipo = t.key;
                      _caracteristicas.clear();
                    }),
            ),
        ],
      ),
    ),
  );

  Widget _selectorFoto(ThemeData theme) {
    final scheme = theme.colorScheme;
    final deshabilitado = _ocupado || _eligiendoFoto;
    if (_foto == null) {
      return Material(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: deshabilitado ? null : _elegirFoto,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  size: 36,
                  color: scheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegir foto',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Opcional · una foto ayuda a reconocerla',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            _foto!.bytes,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Text('No pudimos mostrar la vista previa.'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: deshabilitado ? null : _elegirFoto,
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Cambiar foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _ocupado ? null : () => setState(() => _foto = null),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Quitar foto'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _seccionMascota(ThemeData theme) => SeccionFormulario(
    titulo: _tipo == 4 ? 'La mascota que buscás' : 'La mascota',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: const ValueKey('campo:Tipo de mascota'),
          child: SegmentedButton<int>(
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
            selected: {_mascota},
            onSelectionChanged: _ocupado
                ? null
                : (s) => _cambiarMascota(s.first),
          ),
        ),
        const SizedBox(height: 14),
        _selectorFoto(theme),
        if (_errorFoto != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _errorFoto!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_tipo != 4) ...[
          const SizedBox(height: 14),
          TextFormField(
            controller: _nombre,
            enabled: !_ocupado,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nombre (opcional)',
              counterText: '',
            ),
          ),
        ],
      ],
    ),
  );

  Widget? _muestraColor(String campo, int id) =>
      campo == 'colorPredominante' ? MuestraColor(id: id) : null;

  Widget _seccionCaracteristicas(ThemeData theme) => SeccionFormulario(
    titulo: _tipo == 4
        ? 'Características que buscás (opcionales)'
        : 'Características (opcionales)',
    subtitulo: _tipo == 4 ? 'Dejá sin elegir lo que te resulte indistinto.' : 'Si no conocés algún dato, dejalo sin elegir. Tocá de nuevo para desmarcar.',
    child: FutureBuilder<List<CaracteristicaMascotaDto>>(
      future: _opciones,
      builder: (context, snapshot) {
        // No mostrar opciones del animal anterior mientras llega la nueva consulta.
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Column(
            children: [
              const Text(
                'No pudimos cargar las características. Podés publicar sin completarlas.',
              ),
              TextButton(
                onPressed: _ocupado
                    ? null
                    : () => setState(() {
                        _opciones = _cargarOpciones();
                      }),
                child: const Text('Reintentar características'),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            for (final campo in snapshot.data!)
              KeyedSubtree(
                key: ValueKey('campo:${campo.nombre}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(campo.nombre, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    SelectorOpciones(
                      habilitado: !_ocupado,
                      opciones: [
                        for (final o in campo.opciones)
                          OpcionSelector(
                            o.id,
                            o.nombre,
                            adorno: _muestraColor(campo.campo, o.id),
                          ),
                      ],
                      seleccion: _caracteristicas[campo.campo],
                      // Sin elegir = sin indicar: el campo no se envía.
                      onChanged: (v) => setState(() {
                        if (v == null) {
                          _caracteristicas.remove(campo.campo);
                        } else {
                          _caracteristicas[campo.campo] = v;
                        }
                      }),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _campoFecha(ThemeData theme) => FormField<DateTime>(
    validator: (_) => _fecha == null ? 'Elegí la fecha.' : null,
    builder: (field) => InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _ocupado
          ? null
          : () async {
              final value = await showDatePicker(
                context: context,
                initialDate: _fecha ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (!mounted || value == null) return;
              setState(() => _fecha = value);
              field.didChange(value);
            },
      child: InputDecorator(
        isEmpty: _fecha == null,
        decoration: InputDecoration(
          labelText: _tipo == 1
              ? '¿Cuándo se perdió?'
              : '¿Cuándo la encontraste?',
          hintText: 'Elegir fecha',
          prefixIcon: const Icon(Icons.event_rounded),
          errorText: field.errorText,
        ),
        child: _fecha == null ? null : Text(fechaVisible(_fecha!)),
      ),
    ),
  );

  Widget _seccionDondeCuando(ThemeData theme) => SeccionFormulario(
    titulo: _tipo <= 2 ? 'Dónde y cuándo' : 'Dónde',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_tipo <= 2) ...[_campoFecha(theme), const SizedBox(height: 14)],
        CampoUbicacion(
          service: widget.ubicacion,
          obligatorio: true,
          enabled: !_ocupado,
          onChanged: (_, l) => _localidad = l,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _zona,
          enabled: !_ocupado,
          maxLength: 250,
          validator: _tipo == 4 ? null : requerido,
          decoration: InputDecoration(
            labelText: _tipo == 4
                ? 'Zona aproximada (opcional)'
                : 'Zona aproximada',
            hintText: 'Barrio, plaza o calles cercanas',
            counterText: '',
          ),
        ),
      ],
    ),
  );

  Widget _seccionContacto(ThemeData theme) => SeccionFormulario(
    titulo: 'Contacto',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _contacto,
          enabled: !_ocupado,
          maxLength: 500,
          validator: requerido,
          decoration: const InputDecoration(
            labelText: 'Información de contacto',
            hintText: 'Teléfono, WhatsApp o email',
            prefixIcon: Icon(Icons.call_rounded),
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ColoresApp.ambarSuave,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: ColoresApp.ambar,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'El contacto que ingreses será visible para quienes consulten el aviso.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _barraPublicar(ThemeData theme) => Material(
    color: theme.scaffoldBackgroundColor,
    elevation: 6,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  style: ColoresApp.accionPrincipal,
                  onPressed: _ocupado ? null : _publicar,
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(_ocupado ? 'Publicando…' : 'Publicar aviso'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) => Scaffold(
        appBar: BarraSuperior(auth: widget.auth, titulo: 'Publicar un aviso'),
        bottomNavigationBar: widget.auth.autenticado && !widget.auth.restaurando
            ? _barraPublicar(theme)
            : null,
        body: RequiereSesion(
          auth: widget.auth,
          child: ContenidoFormulario(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _encabezado(theme),
                  _seccionTipo(),
                  _seccionMascota(theme),
                  _seccionCaracteristicas(theme),
                  SeccionFormulario(
                    titulo: 'Descripción',
                    subtitulo: 'Señas particulares, collar, comportamiento o lo que ayude a reconocerla.',
                    child: TextFormField(
                      controller: _descripcion,
                      enabled: !_ocupado,
                      maxLength: 3000,
                      minLines: 3,
                      maxLines: 6,
                      validator: descripcionValida,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  _seccionDondeCuando(theme),
                  _seccionContacto(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
