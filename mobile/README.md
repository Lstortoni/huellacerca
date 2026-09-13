# Huella Cerca — app Flutter

Inicio público conectado a `/health` y `/api/provincias?paisCodigo=AR`, con carga y reintento. El icono de cuenta abre ingreso y registro; con sesión muestra perfil y cierre de sesión. La selección de provincia del inicio vive en memoria. El registro tiene su propia selección de provincia/localidad y crea la cuenta mediante la API.

## Dónde se programa

El código compartido está en `lib/`. Pantallas, servicios y DTO son archivos `.dart`. La interfaz se construye con widgets escritos en Dart; no usamos un archivo XAML separado como en MAUI.

```text
lib/
  main.dart
  app.dart
  core/
    config/api_config.dart
    network/api_client.dart
    network/api_exception.dart
    storage/session_storage.dart
  pages/
    inicio_page.dart
    login_page.dart
    registro_page.dart
    perfil_page.dart
  services/
    ubicacion_service.dart
    auth_service.dart
  models/
    provincia_dto.dart
    localidad_dto.dart
    auth_dto.dart
  widgets/
    barra_superior.dart
    selector_localidad.dart
```

- `main.dart`: entrada. `runApp` inicia `HuellaCercaApp`.
- `app.dart`: crea cliente HTTP y servicio de ubicación, configura tema y pantalla inicial con `MaterialApp`. Tiene responsabilidades similares al arranque y configuración de MAUI. Cierra el cliente cuando se destruye el widget raíz.
- `core/`: piezas compartidas, como configuración y comunicación HTTP.
- `pages/`: pantallas, con sus widgets visuales y su estado.
- `services/`: servicios que consultan la API, reutilizables por las pantallas.
- `models/`: DTO que representan los datos enviados o recibidos de la API.
- `widgets/`: piezas visuales reutilizables. Una página también es un widget, pero representa una pantalla completa. La barra se inserta en `Scaffold.appBar` y el selector de localidades es un diálogo.
- `provincia_dto.dart`: equivalente a un DTO C#. Define `id`, `nombre` y `paisCodigo`; `fromJson` convierte y valida el objeto recibido de la API.
- `ubicacion_service.dart`: conoce el endpoint y devuelve `Future<List<ProvinciaDto>>`, comparable con `Task<List<ProvinciaDto>>` en C#.
- `api_client.dart`: realiza HTTP, decodifica JSON y transforma errores de red, tiempo de espera y estado HTTP en `ApiException`.
- `inicio_page.dart`: widgets visuales y estado de pantalla: carga, error, lista y selección.

Estos nombres de carpetas son convenciones elegidas para organizar el código, no una obligación de Flutter. Los DTO Dart representan el contrato JSON, sin referenciar las clases C# ni las entidades EF.

## Flujo al abrir la app

1. `main()` llama `runApp(const HuellaCercaApp())`.
2. `app.dart` crea dependencias y muestra `InicioPage`.
3. `initState()` de la pantalla llama `_cargar()` al crearse.
4. Consulta `/health`, que comprueba que la API responde, no la base.
5. `UbicacionService.getProvincias()` pide el catálogo mediante `ApiClient`.
6. `ProvinciaDto.fromJson()` transforma cada elemento en un objeto Dart.
7. La pantalla recibe la lista y usa `setState()` para actualizar la interfaz.
8. Ante un error muestra un mensaje y permite reintentar.

`build()` describe la interfaz según el estado. `setState()` avisa que cambió ese estado; Flutter reconstruye los widgets correspondientes. `mounted` comprueba que la pantalla sigue existiendo después de esperar una respuesta asíncrona.

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

`app.dart` crea una sola instancia de `AuthService` y la entrega a las páginas. Conserva `InicioPage` como `home`; registra las rutas `/login`, `/registro` y `/perfil`. La barra usa `Navigator.pushNamed` para abrirlas. Al ingresar o registrarse se vuelve al inicio. Cerrar sesión vuelve al inicio público.

`AuthService` extiende `ChangeNotifier`: guarda el estado de sesión y avisa cuando cambia. `BarraSuperior` escucha esos avisos con `ListenableBuilder` y actualiza las opciones. La barra no hace llamadas HTTP ni almacena tokens.

- `POST /api/auth/register`: formulario con nombre, apellido, email, contraseña, confirmación, teléfono opcional y localidad. Crear cuenta inicia sesión.
- `POST /api/auth/login`: email y contraseña.
- `GET /api/auth/me`: perfil de solo lectura, consultado con Bearer access token.
- `POST /api/auth/refresh`: renueva usando exclusivamente el refresh en el cuerpo JSON. Las consultas GET protegidas reintentan una sola vez tras un 401; las simultáneas comparten una renovación. Login y registro no se reintentan automáticamente.
- `POST /api/auth/logout`: revoca la sesión en la API y borra los datos locales. Si falla la red, la app informa que no pudo confirmar el cierre en el servidor.

`SecureSessionStorage` guarda la respuesta de sesión en una única entrada de almacenamiento seguro; nunca guarda la contraseña. Usa [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage). Android tiene `allowBackup=false` siguiendo la configuración del paquete. Al abrir se recupera la sesión y se consulta el perfil; si el JWT venció se renueva. El vencimiento absoluto del refresh lo determina la API (30 días actualmente). Si una renovación falla se limpia la sesión para evitar reutilizar un refresh que pudo haber rotado; será necesario ingresar nuevamente. Un fallo de red al consultar el perfil, sin renovación, conserva la sesión.

`SelectorLocalidad` consulta páginas de 20 resultados y permite buscar por nombre. Cambiar de provincia borra la localidad seleccionada para evitar una combinación incorrecta.

La edición de perfil, recuperación de contraseña, publicaciones de mascotas y pantallas de recomendaciones quedan para los próximos bloques. La autenticación está preparada y probada inicialmente en Android; iOS necesita su verificación y configuración en macOS antes de publicarse.

### Prueba de integración Android y API local

Con emulador, API y catálogo disponibles, desde `mobile`:

```powershell
flutter test integration_test/auth_api_test.dart -d emulator-5554
```

Crea una cuenta `hc-mobile-test-*` en la base local, que queda como dato de prueba. Usa una clave de almacenamiento independiente de la sesión habitual. Verifica registro, recuperación del almacenamiento seguro con una nueva instancia de la app, perfil, logout y login; termina cerrando las sesiones de prueba. Solo admite el host local/emulador y puerto 5080.

Después de una prueba de integración, ejecutar `flutter run -d emulator-5554` para volver a instalar la app normal. Al agregar este plugin nativo se necesita detener y volver a ejecutar Flutter; hot reload por sí solo no lo incorpora.
