# Huella Cerca — app Flutter

## Características al publicar

`PublicarMascotaPage` obtiene opciones de `PublicacionService.caracteristicas(tipoMascota)` al abrir y cambiar de especie. El servicio consume GET `/api/publicaciones/caracteristicas`; los DTO están en `models/publicacion_dto.dart`. Los textos y valores de los selectores proceden de la API.

Los cuatro tipos de aviso permiten características opcionales. Para Busco adoptar son preferencias y no se pide nombre ni fecha del suceso. Sin indicar omite el campo del JSON; el cero utilizado por el selector nunca se envía. Al cambiar especie o tipo de aviso se limpian las selecciones. Un error del catálogo permite reintentar o publicar sin características. `CrearPublicacionRequest` envía los valores elegidos y `PublicacionDto` lee los campos opcionales sin romper avisos anteriores.

El detalle muestra solo las características informadas, usando las etiquetas de la API. En Busco adoptar se titulan Características que busca. La búsqueda y Mis publicaciones permiten filtros opcionales por características al seleccionar especie, con Cualquiera y Quitar filtros de características. Cambiar especie limpia las selecciones. Los filtros son exactos, combinados con AND, y excluyen avisos sin ese dato; sin filtros se incluyen también los avisos anteriores. Un error del catálogo permite reintentar sin ocultar el resto del detalle. La instalación en Android la realiza el usuario.

Inicio con tarjetas públicas de búsqueda y acciones de participación según la sesión. No consulta `/health` ni provincias para mostrarse. El icono de cuenta abre ingreso y registro; con sesión muestra perfil y cierre de sesión. El registro conserva la selección de provincia/localidad y crea la cuenta mediante la API.

## Dónde se programa

Adopción: el selector distingue Doy en adopción (3) y Busco adoptar (4). Ambos ocultan fecha del suceso y usan fecha de publicación. Busco adoptar también oculta nombre y permite omitir zona. Tipo de mascota, descripción, localidad y contacto continúan obligatorios. El detalle muestra el contacto público para que otra persona pueda comunicarse; no hay chat interno. Fotos pendientes.

El código compartido está en `lib/`. Pantallas, servicios y DTO son archivos `.dart`. La interfaz se construye con widgets escritos en Dart; no usamos un archivo XAML separado como en MAUI.

```text
lib/
  main.dart
  app.dart
  core/
    config/api_config.dart
    di/service_registration.dart
    network/api_client.dart
    network/http_api_client.dart
    network/api_exception.dart
    storage/session_storage.dart
    storage/secure_session_storage.dart
  pages/
    inicio_page.dart
    login_page.dart
    registro_page.dart
    perfil_page.dart
    mascotas_page.dart
    publicacion_detalle_page.dart
    publicar_mascota_page.dart
    recomendaciones_page.dart
    prestador_detalle_page.dart
    recomendar_servicio_page.dart
  services/
    contracts/
      ubicacion_service.dart
      auth_service.dart
      publicacion_service.dart
      recomendacion_service.dart
    implementations/
      ubicacion_service_api.dart
      auth_service_api.dart
      publicacion_service_api.dart
      recomendacion_service_api.dart
  models/
    provincia_dto.dart
    localidad_dto.dart
    auth_dto.dart
    pagina_dto.dart
    publicacion_dto.dart
    recomendacion_dto.dart
  widgets/
    barra_superior.dart
    selector_localidad.dart
    tarjeta_inicio.dart
    campo_ubicacion.dart
    contenido_formulario.dart
    lista_paginada.dart
```

- `main.dart`: entrada. Ejecuta `configurarServicios()` y luego `runApp(const HuellaCercaApp())`.
- `app.dart`: obtiene los servicios con `getIt<Contrato>()`, restaura la sesión y configura tema, inicio y rutas. Entrega servicios por constructor a las páginas.
- `core/di/service_registration.dart`: registra contratos e implementaciones con `registerLazySingleton`. Cada servicio se crea al pedirlo por primera vez y se reutiliza durante la ejecución.
- `core/`: piezas compartidas, como configuración y comunicación HTTP.
- `pages/`: pantallas, con sus widgets visuales y su estado.
- `services/contracts/`: operaciones y propiedades que conocen las páginas; no contienen la implementación.
- `services/implementations/`: implementaciones API de esos contratos; dependen a su vez del contrato `ApiClient`.
- `models/`: DTO que representan los datos enviados o recibidos de la API.
- `widgets/`: piezas visuales reutilizables. Una página también es un widget, pero representa una pantalla completa. La barra se inserta en `Scaffold.appBar` y el selector de localidades es un diálogo.
- `provincia_dto.dart`: equivalente a un DTO C#. Define `id`, `nombre` y `paisCodigo`; `fromJson` convierte y valida el objeto recibido de la API.
- `ubicacion_service.dart`: contrato que devuelve `Future<List<ProvinciaDto>>`, comparable con `Task<List<ProvinciaDto>>` en C#. `ubicacion_service_api.dart` conoce los endpoints y convierte los DTO.
- `api_client.dart`: contrato de transporte, sin tipos del paquete HTTP. `http_api_client.dart` realiza HTTP, decodifica JSON y transforma errores en `ApiException`.
- `inicio_page.dart`: inicio que escucha el contrato de sesión y muestra dos o cinco tarjetas. `tarjeta_inicio.dart` es el componente visual reutilizado por cada acceso.

Estos nombres de carpetas son convenciones elegidas para organizar el código, no una obligación de Flutter. Los DTO Dart representan el contrato JSON, sin referenciar las clases C# ni las entidades EF.

## Flujo al abrir la app

1. `main()` registra los servicios y ejecuta `runApp(const HuellaCercaApp())`.
2. `app.dart` inicia la restauración de sesión y muestra `InicioPage(auth: getIt<AuthService>())`.
3. Inicio recibe solo el contrato `AuthService`. `ListenableBuilder` escucha sus notificaciones.
4. Siempre muestra Buscar mascotas y Servicios recomendados. Mientras restaura la sesión, muestra un indicador sin bloquear esos accesos.
5. Sin sesión agrega la invitación a ingresar/registrarse. Con sesión muestra el saludo y las tarjetas Publicar un aviso, Mis publicaciones y Recomendar un servicio.
6. Al tocar una tarjeta, su callback `onTap` llama `Navigator.pushNamed` con la ruta correspondiente.
7. `app.dart` resuelve la ruta y muestra su página destino.
8. Login y registro vuelven al inicio al completarse; `notifyListeners()` actualiza tanto el inicio como la barra. Logout vuelve a mostrar las dos tarjetas públicas.

| Tarjeta | Ruta | Estado de esta versión |
| --- | --- | --- |
| Buscar mascotas | `/mascotas` | Filtros, paginación, detalle y contacto públicos. |
| Servicios recomendados | `/servicios` | Búsqueda por texto, rubro y ubicación; detalle público. |
| Publicar un aviso | `/mascotas/publicar` | Formulario autenticado con una foto opcional; después abre el detalle y sube la foto. |
| Recomendar un servicio | `/servicios/recomendar` | Busca similares, permite elegir prestador o crear uno con la recomendación. |

Los destinos utilizan servicios reales. Las páginas reciben contratos por constructor; no llaman a HTTP directamente. Los detalles se abren con MaterialPageRoute pasando el ID y los mismos contratos. Después de crear se reemplaza el formulario por el detalle para evitar volver accidentalmente al formulario enviado. Login y registro conservan su regreso al inicio.

En mascotas se muestran activas por defecto. Se puede filtrar Perdida/Encontrada, Perro/Gato/Otro, estado, provincia, localidad, zona y rango de fechas del suceso. Con sesión aparece Solo mis publicaciones; para encontrar avisos propios resueltos, seleccionar Resuelta o Todas y Buscar. El detalle ofrece Marcar como resuelta únicamente al autor de una publicación activa; pide confirmación y actualiza el estado con PATCH. Al volver a la búsqueda se recarga la página de resultados. La API verifica la autoría independientemente de lo que muestre Flutter.

En recomendaciones, la selección de un prestador similar evita crear uno nuevo. También se permite crear otro aunque haya coincidencias. Modificar nombre, rubro o localidad invalida la búsqueda y selección previas. El DTO de creación envía solo prestadorServicioId o nuevoPrestador, nunca ambos. Dirección, teléfono y enlace son opcionales para el nuevo prestador. No hay llamadas a Google Places.

Las búsquedas incluyen carga, error con reintento, resultados vacíos y páginas de 20 elementos. Los formularios validan campos y requieren sesión. La foto es opcional: selección desde galería, reducción inicial, subida desde el detalle, reintento sin duplicar el aviso y controles del autor para reemplazar/eliminar. Se muestra en detalle, búsqueda y coincidencias. Configuración R2 exclusivamente en el backend: [guía de fotos](../docs/fotos-r2.md). Se pueden modificar los aspectos seleccionados y retirar la recomendación desde la ficha del prestador.

La pantalla de inicio es un `StatelessWidget`: su información cambiante está en `AuthService`, que avisa a `ListenableBuilder`. No necesita su propia carga de provincias ni estado local. La disposición vertical permite desplazarse y limita el ancho en pantallas grandes.

## Configuración y ejecución

URL y espera máxima (15 segundos): `lib/core/config/api_config.dart`. Por defecto: `http://10.0.2.2:5080`. Desde el emulador Android, `10.0.2.2` permite acceder al host donde corre Docker. [Referencia de Android](https://developer.android.com/studio/run/emulator-networking-address).

Con Docker Desktop iniciado, desde la raíz:

```powershell
docker compose up -d
cd mobile
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Usar el identificador Android que devuelva `flutter devices`. Si está cerrado, abrir el emulador desde Android Studio o con `flutter emulators --launch Pixel_8_API_37`. También se puede iniciar con F5 usando `Huella Cerca (Flutter)` en VS Code.

Para otra URL sin editar código:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

`--dart-define` se aplica al iniciar/compilar; cambiarlo requiere reiniciar la ejecución. La app no lee el `.env` de Docker. Un teléfono físico requiere configurar la dirección de la PC y acceso de red; esta configuración se preparó para el emulador Android.

El permiso de Internet está en `android/app/src/main/AndroidManifest.xml`. HTTP sin TLS está habilitado solo para desarrollo en `android/app/src/debug/AndroidManifest.xml`. iOS conserva su proyecto generado; se verificará en esa plataforma cuando corresponda.

## Otros archivos y pruebas

- `pubspec.yaml`: dependencias, versión y recursos; agregamos `http` para consumir la API.
- `pubspec.lock`: versiones resueltas; se versiona.
- `android/` e `ios/`: integración nativa. La pantalla compartida está en `lib/`.
- `test/`: pruebas de carga, selección, reintento, catálogo vacío y errores HTTP/JSON.
- `build/` y `.dart_tool/`: generados; no editarlos.

```powershell
flutter analyze
flutter test
```

Durante `flutter run`, guardar y presionar `r` aplica hot reload; `R` reinicia el estado. Cambiar Dart no requiere reconstruir los contenedores.

## Sesión y navegación

`configurarServicios()` registra `AuthServiceApi` como implementación compartida de `AuthService`. `app.dart` entrega ese contrato a las páginas, conserva `InicioPage` como `home` y registra las rutas `/login`, `/registro` y `/perfil`. La barra usa `Navigator.pushNamed` para abrirlas. Al ingresar o registrarse se vuelve al inicio. Cerrar sesión vuelve al inicio público.

`AuthService` es un contrato que implementa `Listenable`: incluye operaciones, propiedades de lectura y notificaciones de sesión. `AuthServiceApi` extiende `ChangeNotifier` e implementa ese contrato. `BarraSuperior` escucha el contrato con `ListenableBuilder` y actualiza las opciones; no conoce la clase API, no hace llamadas HTTP ni almacena tokens.

## Registro y sustitución de servicios con get_it

El registro está en `core/di/service_registration.dart`. Su papel es parecido al registro de interfaces en `Program.cs` de .NET:

```dart
getIt.registerLazySingleton<AuthService>(
  () => AuthServiceApi(getIt<ApiClient>(), getIt<SessionStorage>()),
  dispose: (auth) => auth.dispose(),
);
```

En `app.dart` se obtiene el contrato y se entrega a la página:

```dart
'/login': (_) => LoginPage(auth: getIt<AuthService>()),
```

Las páginas, widgets y servicios no buscan objetos globales: siguen recibiendo contratos por constructor. Solo el registro y `app.dart` usan el localizador. `get_it` no completa constructores automáticamente; las funciones registradas describen cómo crear cada objeto. No existe ya `AppDependencies`.

Los servicios duran toda la ejecución. No se liberan al cambiar de página ni al desmontar el widget raíz. En pruebas se desmonta la app y se ejecuta `await getIt.reset()` para eliminar registros y llamar a los callbacks de liberación de autenticación y HTTP. El reset no borra la sesión persistida del usuario. Cada prueba configura sus propios registros; no se permite registrar dos veces un mismo tipo sin reset.

`test/dependencies_test.dart` sustituye los servicios completos por mocks, sin cambiar las páginas:

```dart
getIt.registerSingleton<AuthService>(
  AuthServiceMock(),
  dispose: (auth) => auth.dispose(),
);
```

Los mocks viven en `test/support/`. Las pruebas de HTTP usan transporte y almacenamiento simulados. El inicio no necesita servicios de ubicación ni transporte HTTP; las pantallas de registro, búsqueda y publicación usan el contrato UbicacionService.

### Comportamiento de la implementación de sesión

- `POST /api/auth/register`: formulario con nombre, apellido, email, contraseña, confirmación, teléfono opcional y localidad. Crear cuenta inicia sesión.
- `POST /api/auth/login`: email y contraseña.
- `GET /api/auth/me`: perfil de solo lectura, consultado con Bearer access token.
- `POST /api/auth/refresh`: renueva usando exclusivamente el refresh en el cuerpo JSON. GET, POST y PATCH protegidos reintentan una sola vez tras un 401; las solicitudes simultáneas comparten una renovación. Los envíos no se reintentan automáticamente ante errores de red, 400, 403 o 500. Login y registro no se reintentan automáticamente.
- `POST /api/auth/logout`: revoca la sesión en la API y borra los datos locales. Si falla la red, la app informa que no pudo confirmar el cierre en el servidor.

`SecureSessionStorage` guarda la respuesta de sesión en una única entrada de almacenamiento seguro; nunca guarda la contraseña. Usa [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage). Android tiene `allowBackup=false` siguiendo la configuración del paquete. Al abrir se recupera la sesión y se consulta el perfil; si el JWT venció se renueva. El vencimiento absoluto del refresh lo determina la API (30 días actualmente). Si una renovación falla se limpia la sesión para evitar reutilizar un refresh que pudo haber rotado; será necesario ingresar nuevamente. Un fallo de red al consultar el perfil, sin renovación, conserva la sesión.

`SelectorLocalidad` consulta páginas de 20 resultados y permite buscar por nombre. Cambiar de provincia borra la localidad seleccionada para evitar una combinación incorrecta.

La edición de perfil, recuperación de contraseña y subida de fotografías quedan pendientes. La autenticación está preparada y probada inicialmente en Android; iOS necesita su verificación y configuración en macOS antes de publicarse.

### Prueba de integración Android y API local

Con emulador, API y catálogo disponibles, desde `mobile`:

```powershell
flutter test integration_test/auth_api_test.dart -d emulator-5554
```

Crea una cuenta `hc-mobile-test-*` en la base local, que queda como dato de prueba. Usa una clave de almacenamiento independiente de la sesión habitual. Verifica registro, recuperación del almacenamiento seguro con una nueva instancia de la app, perfil, logout y login; termina cerrando las sesiones de prueba. Solo admite el host local/emulador y puerto 5080.

Después de una prueba de integración, ejecutar `flutter run -d emulator-5554` para volver a instalar la app normal. Al agregar este plugin nativo se necesita detener y volver a ejecutar Flutter; hot reload por sí solo no lo incorpora.

Mis publicaciones (/mascotas/mias) es un acceso autenticado del inicio: reutiliza la búsqueda fijando MascoteroId y muestra todos los estados inicialmente. Conserva el autor al aplicar filtros y retira el listado al cerrar sesión. La búsqueda pública mantiene Solo mis publicaciones como filtro opcional. Las etiquetas de búsqueda describen avisos ajenos (Mascotas en adopción / Personas que quieren adoptar) y las de creación expresan la intención del autor (Doy en adopción / Busco adoptar).
## Recomendaciones con aspectos

1. `RecomendarServicioPage` busca similares por nombre, rubro y localidad.
2. `GestionRecomendacion` consulta si el usuario ya recomienda cada ficha. “Recomendar” guarda el voto y abre `PrestadorDetallePage`. Si ya lo recomienda, ofrece modificar aspectos.
3. Si no reconoce ningún resultado, “Es otro servicio: crear uno nuevo” permite completar datos opcionales y “Crear y recomendar”.
4. Desde este recorrido se abre la ficha con `permitirGestion: true`. La recomendación ya está guardada: elegir aspectos es opcional.
5. “Guardar aspectos” reemplaza la selección, incluso por una lista vacía. “Retirar recomendación” pide confirmación y elimina el voto.

El servicio sigue inyectado por su contrato con get_it. `RecomendacionServiceApi` consume la API pública para prestadores/catálogo y usa `AuthService` para GET/POST/PUT/DELETE protegidos. Las Pages no construyen HTTP ni JWT.

El listado público devuelve prestadores (una ficha por ID), no opiniones individuales. No hay título, comentario ni estrellas. Se permiten fichas parecidas: la unicidad del voto corresponde a un par mascotero/prestador, no a la identidad real de un comercio.

Desde **Servicios recomendados**, la ficha es pública y de solo lectura, incluso con sesión iniciada. Muestra datos del servicio, cantidad de recomendaciones, aspectos agregados y nombres de quienes lo recomiendan (paginados). No consulta la recomendación propia ni ofrece recomendar, guardar aspectos, retirar o iniciar sesión para recomendar. Estas acciones se ofrecen exclusivamente desde **Recomendar un servicio**.

El listado público excluye prestadores con cero recomendaciones. Esas fichas permanecen en la búsqueda de similares del recorrido para recomendar.

## Editar y reabrir avisos

En el detalle de un aviso propio, el lápiz junto al nombre o "Editar aviso" abren el formulario de Publicar con los datos cargados (`/mascotas/editar`). El tipo de aviso no se puede cambiar y la foto se gestiona desde el detalle. Si el aviso cambió mientras se editaba, la API responde 409 y la app vuelve al detalle actualizado. Un aviso resuelto ofrece "Reabrir aviso". Detalle en [docs/publicaciones-mascotas.md](../docs/publicaciones-mascotas.md).

## Notificaciones

Con sesión, la barra muestra una campanita con las notificaciones sin leer (posibles coincidencias con tus avisos). El contador se consulta cada 2 minutos mientras la app está abierta, y además al iniciar sesión, al volver a la app y al abrir la página; en segundo plano no consulta. Tocar una notificación la marca como leída y abre el aviso que coincide; "Ver mi aviso" abre el propio.

- `models/notificacion_dto.dart`: notificación con el resumen de ambos avisos.
- `services/contracts/notificacion_service.dart` e `implementations/notificacion_service_api.dart`: contador observable, temporizador y lecturas.
- `widgets/notificaciones_scope.dart`: publica el servicio una vez en `app.dart` para que `BarraSuperior` lo use sin recibirlo en cada página.
- `pages/notificaciones_page.dart` y `widgets/tarjeta_notificacion.dart`: listado, filtro No leídas y "Marcar todas como leídas".

Detalle del contrato y de la generación en la API: [docs/notificaciones.md](../docs/notificaciones.md).
