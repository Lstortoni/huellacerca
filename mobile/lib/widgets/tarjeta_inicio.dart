import 'package:flutter/material.dart';

/// Acceso reutilizable: muestra una acción y avisa cuando la persona la toca.
/// La variante destacada usa fondo de color e ícono sólido; la compacta,
/// fondo blanco e ícono sobre un círculo suave.
class TarjetaInicio extends StatelessWidget {
  const TarjetaInicio({
    super.key,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.colorSuave,
    required this.onTap,
    this.descripcion,
    this.destacada = false,
  });
  final String titulo;
  final String? descripcion;
  final IconData icono;
  final Color color, colorSuave;
  final VoidCallback onTap;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radio = BorderRadius.circular(destacada ? 24 : 20);
    return Material(
      color: destacada ? colorSuave : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radio,
        side: destacada
            ? BorderSide.none
            : BorderSide(color: colorSuave, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(destacada ? 20 : 16),
            child: destacada ? _destacada(theme) : _compacta(theme),
          ),
        ),
      ),
    );
  }

  Widget _icono(double lado, double tamano, {required bool solido}) =>
      ExcludeSemantics(
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: solido ? color : colorSuave,
            borderRadius: BorderRadius.circular(lado / 3),
          ),
          child: Icon(
            icono,
            size: tamano,
            color: solido ? Colors.white : color,
          ),
        ),
      );

  Widget _destacada(ThemeData theme) => Row(
    children: [
      _icono(56, 30, solido: true),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (descripcion != null) ...[
              const SizedBox(height: 4),
              Text(descripcion!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
      const SizedBox(width: 8),
      ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, color: color)),
    ],
  );

  Widget _compacta(ThemeData theme) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _icono(44, 24, solido: false),
      const SizedBox(height: 12),
      Text(
        titulo,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
