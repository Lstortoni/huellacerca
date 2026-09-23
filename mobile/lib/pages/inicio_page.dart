import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../services/contracts/auth_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/tarjeta_inicio.dart';

/// Inicio público. Escucha la sesión para agregar las acciones de participación.
/// Las tarjetas se estiran para ocupar la pantalla; si no entran, se desplaza.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: auth),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final conSesion = auth.autenticado && !auth.restaurando;
          void ir(String ruta) => Navigator.of(context).pushNamed(ruta);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 20).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Bienvenida(auth: auth, conSesion: conSesion, ir: ir),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TarjetaInicio(
                              titulo: 'Buscar mascotas',
                              descripcion:
                                  'Perdidas, encontradas y en adopción.',
                              icono: Icons.search_rounded,
                              color: ColoresApp.verde,
                              colorSuave: ColoresApp.verdeSuave,
                              destacada: true,
                              onTap: () => ir('/mascotas'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TarjetaInicio(
                              titulo: 'Servicios recomendados',
                              descripcion: 'Veterinarias, peluquerías, paseadores y más.',
                              icono: Icons.storefront_rounded,
                              color: ColoresApp.ambar,
                              colorSuave: ColoresApp.ambarSuave,
                              destacada: true,
                              onTap: () => ir('/servicios'),
                            ),
                          ),
                          if (conSesion) ...[
                            const SizedBox(height: 12),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: TarjetaInicio(
                                      titulo: 'Mis publicaciones',
                                      icono: Icons.list_alt_rounded,
                                      color: ColoresApp.azul,
                                      colorSuave: ColoresApp.azulSuave,
                                      onTap: () => ir('/mascotas/mias'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TarjetaInicio(
                                      titulo: 'Recomendar un servicio',
                                      icono: Icons.recommend_rounded,
                                      color: ColoresApp.violeta,
                                      colorSuave: ColoresApp.violetaSuave,
                                      onTap: () => ir('/servicios/recomendar'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Banner de saludo con la acción principal según el estado de la sesión.
class _Bienvenida extends StatelessWidget {
  const _Bienvenida({
    required this.auth,
    required this.conSesion,
    required this.ir,
  });
  final AuthService auth;
  final bool conSesion;
  final void Function(String ruta) ir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = auth.usuario?.mascotero.nombre.trim() ?? '';
    const botonPrincipal = ColoresApp.accionPrincipal;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.verde, ColoresApp.verdeClaro],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Huellas decorativas de fondo.
          Positioned(
            right: -18,
            top: -14,
            child: Transform.rotate(
              angle: 0.4,
              child: Icon(
                Icons.pets_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 92,
            top: 58,
            child: Transform.rotate(
              angle: -0.3,
              child: Icon(
                Icons.pets_rounded,
                size: 40,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  conSesion
                      ? (nombre.isEmpty ? 'Hola' : 'Hola, $nombre')
                      : 'Más cerca de quienes nos necesitan.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  conSesion ? '¿Qué querés hacer hoy?' : 'Una comunidad para ayudar a las mascotas y compartir buenas experiencias.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 18),
                if (auth.restaurando) ...[
                  const LinearProgressIndicator(
                    color: ColoresApp.ambarBoton,
                    backgroundColor: Colors.white24,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Recuperando tu sesión…',
                    style: TextStyle(color: Colors.white),
                  ),
                ] else if (conSesion)
                  FilledButton.icon(
                    style: botonPrincipal,
                    onPressed: () => ir('/mascotas/publicar'),
                    icon: const Icon(Icons.campaign_rounded),
                    label: const Text('Publicar un aviso'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: botonPrincipal,
                          onPressed: () => ir('/login'),
                          child: const Text('Ingresar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size(0, 52),
                          ),
                          onPressed: () => ir('/registro'),
                          child: const Text('Registrarse'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
