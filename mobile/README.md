# Huella Cerca — app Flutter

Primera conexión con la API: consulta `/health` y `/api/provincias?paisCodigo=AR`. Muestra carga, errores con reintento y un selector de provincias. La selección vive en memoria; todavía no registra usuarios ni modifica datos.

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
  features/
    inicio/presentation/inicio_page.dart
    ubicacion/models/provincia_dto.dart
    ubicacion/services/ubicacion_service.dart
```

- `main.dart`: entrada. `runApp` inicia `HuellaCercaApp`.
- `app.dart`: crea cliente HTTP y servicio de ubicación, configura tema y pantalla inicial con `MaterialApp`. Tiene responsabilidades similares al arranque y configuración de MAUI. Cierra el cliente cuando se destruye el widget raíz.
- `core/`: piezas compartidas, como configuración y comunicación HTTP.
- `features/`: agrupación por funcionalidad. Inicio contiene la pantalla; ubicación contiene datos y consultas reutilizables por el futuro registro.
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

El siguiente bloque incorporará autenticación y almacenamiento seguro de sesión. Esta primera conexión usa endpoints públicos.
