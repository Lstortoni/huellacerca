# Huella Cerca — app Flutter

Primera práctica: el contador de ejemplo de Flutter con el título Huella Cerca. Todavía no se conecta a la API.

## Archivos principales

- `lib/main.dart`: entrada y pantalla de ejemplo; nuestro código Dart empieza aquí.
- `pubspec.yaml`: nombre, versión, dependencias y recursos del proyecto.
- `android/`: proyecto nativo necesario para ejecutar en Android.
- `ios/`: base para iOS; su compilación requiere macOS y Xcode.
- `test/widget_test.dart`: prueba que toca el botón y verifica el incremento.
- `build/` y `.dart_tool/`: archivos generados; no editarlos ni subirlos a Git.

## Ejecutar

Desde la raíz del repositorio:

```powershell
cd mobile
flutter emulators --launch Pixel_8_API_37
flutter devices
flutter run -d <id-del-dispositivo-android>
```

Si el emulador ya está abierto, omitir el comando de lanzamiento. Usar el identificador Android que muestre `flutter devices` (por ejemplo, emulator-5554), no los signos < >.

También podés abrir `mobile` en VS Code, seleccionar el emulador en la barra inferior y presionar F5.

## Primera lectura de main.dart

1. `import` incorpora las herramientas visuales de Flutter.
2. `main()` es el punto de entrada, comparable con el inicio de una aplicación C#.
3. `runApp(const MyApp())` inicia la interfaz usando nuestro widget raíz.
4. `MaterialApp` configura el título, tema y pantalla inicial.
5. `Scaffold` organiza la pantalla: barra superior, contenido y botón flotante.
6. `Text`, `Column` y `Center` muestran texto, apilan elementos y los centran.
7. `_counter` guarda el número; el prefijo `_` lo hace privado a la biblioteca Dart.
8. `onPressed` indica qué función ejecutar al tocar el botón.
9. `setState` avisa a Flutter que cambió el estado para reconstruir la interfaz correspondiente.

`StatelessWidget` no tiene un objeto de estado mutable propio. `StatefulWidget` utiliza un objeto `State`, como el que contiene el contador. `const` crea una instancia constante cuando sus argumentos lo permiten; `final` indica que una variable solo puede asignarse una vez.

## Primer cambio visual

Con `flutter run` activo, cambiar el título de `MyHomePage` en `lib/main.dart`, guardar y presionar `r` en la terminal. El hot reload aplica ese cambio conservando el contador. `R` hace hot restart y reinicia el estado; `q` termina la sesión.

Esta pantalla es una práctica, no el diseño final. El próximo paso será reemplazarla por el inicio de Huella Cerca, incorporando pocos widgets por vez.
