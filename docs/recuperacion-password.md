# Recuperación de contraseña: prueba local

## Recorrido

1. `LoginPage`: enlace **¿Olvidaste tu contraseña?** → ruta `/recuperar-password`.
2. `RecuperarPasswordPage`: tres pasos (email, código, nueva contraseña), espera de reenvío y confirmación final.
3. `RecuperacionServiceApi` implementa el contrato Flutter `RecuperacionService`. Usa el mismo `ApiClient` y `API_BASE_URL` del resto de la app, sin JWT ni llamadas directas a Brevo.
4. `RecuperacionController` recibe los tres pedidos públicos.
5. Al solicitar un correo se encola el email; `EnviarCodigosRecuperacion` llama a `RecuperacionService.EnviarCodigoAsync` en un scope independiente.
6. Ese servicio genera seis dígitos seguros, guarda su huella con `RecuperacionRepository`, obtiene `EmailTemplates.RecuperacionPassword(codigo)` y llama a `BrevoEmailService`.
7. Al verificar, el código se consume y se devuelve un permiso aleatorio temporal. Al restablecer, se consume ese permiso, se actualiza la contraseña y se revocan las sesiones anteriores.

Flutter no guarda el código, la contraseña ni el permiso en almacenamiento permanente. El permiso vive en memoria de la página y no inicia sesión.

## Qué guarda PostgreSQL

La migración `20261019200447_RecuperacionPassword` agrega:

- `recuperaciones_password`: una fila por usuario, identificador del código, HMAC, fechas, intentos fallidos, estado de verificación, hash y vencimiento del permiso temporal, fecha de uso y contadores de envíos.
- `VersionSeguridad` en usuarios y refresh tokens: permite rechazar tokens emitidos antes del cambio de contraseña, incluso ante un login o refresh concurrente.

No se guarda el código legible. Se guarda HMAC-SHA256 del identificador de la solicitud y el código con una clave privada independiente. No es un SHA-256 simple de seis dígitos. El permiso aleatorio de 256 bits se guarda mediante SHA-256; la contraseña usa `PasswordHasher` existente.

Reglas: código válido 10 minutos, máximo 5 errores, uso único; permiso válido 10 minutos y uso único; un reenvío aceptado invalida código y permiso anteriores. Espera mínima de 60 segundos y hasta 3 envíos por hora por cuenta, persistidos en DB. Las operaciones se serializan con bloqueo del usuario dentro de transacciones.

Los JWT incluyen versión de seguridad y se comprueba que su sesión siga activa. Los tokens previos sin versión se aceptan con versión cero mientras su sesión sea válida y el usuario no haya restablecido su contraseña. Logout ahora invalida también el acceso de esa sesión, no sólo su renovación. Se desactivan los dispositivos push del usuario al restablecer.

## Endpoints

```http
POST /api/auth/forgot-password
{"email":"usuario@example.com"}
```

202 con mensaje genérico y `reintentarEnSegundos: 60`, sin revelar la existencia de la cuenta. La aceptación no confirma la entrega. Se aplica un límite de 10 pedidos por minuto por IP a los endpoints de recuperación; exceso: 429.

```http
POST /api/auth/verify-reset-code
{"email":"usuario@example.com","codigo":"012345"}
```

200: `{"resetToken":"...","expiresAtUtc":"..."}`. Código inválido/vencido/usado o cuenta inactiva: 400 genérico. Los ceros iniciales se conservan porque el código es una cadena.

```http
POST /api/auth/reset-password
{"resetToken":"...","password":"NuevaClave...","passwordConfirm":"NuevaClave..."}
```

200: contraseña actualizada. Permiso inválido/vencido/usado o validación incorrecta: 400. Luego ingresar normalmente, sin login automático.

## Configuración local

En `.env` de la raíz, privado y excluido de Git:

```dotenv
BREVO_ENABLED=true
BREVO_SENDER_EMAIL=no-reply@huellacerca.online
BREVO_API_KEY=CLAVE_REAL_DE_BREVO
PASSWORD_RECOVERY_ENABLED=true
PASSWORD_RECOVERY_HMAC_KEY=CLAVE_ALEATORIA_BASE64_DE_AL_MENOS_32_BYTES
```

La clave HMAC es distinta de JWT y Brevo; no cambiarla en cada arranque ni copiarla a Flutter. Cambiarla invalida códigos pendientes. Puede generarse en Linux con `openssl rand -base64 32` y guardarse en el `.env`, sin compartirla. La configuración local y la del VPS son independientes.

Después de actualizar código/configuración, desde la raíz:

```bash
docker compose config --quiet
docker compose up -d --build huellacerca_api
```

Compose ejecuta las migraciones antes de la API. No borrar volúmenes. Estos comandos no importan localidades ni crean cuentas.

El usuario instala/ejecuta la app. Para Android emulado, desde `mobile`:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5080
```

Ese destino es la API de la computadora, no TEST. El APK instalado previamente con la URL del VPS conserva esa URL; no cambia solo. `10.0.2.2` sirve para el emulador Android, no para un celular físico.

1. Usar una cuenta existente en la **base local** y un correo real accesible. Si sólo se registró en TEST, registrarse localmente primero.
2. Ingresar → ¿Olvidaste tu contraseña? → Enviar código.
3. Verificar recepción y estado de entrega en Brevo; revisar spam.
4. Ingresar código, elegir contraseña y volver al login.
5. Comprobar que la nueva contraseña funciona y la anterior no.

No dejar una API Key en capturas ni pegar archivos `.env` en el chat. Los logs del envío no incluyen destinatarios, códigos, contraseñas ni claves.

## Limitaciones y despliegue posterior en VPS

La cola de solicitudes está en memoria, acotada a 100 entradas, con dos consumidores y edad máxima de dos minutos. Evita que el tiempo de respuesta dependa de si el email existe o de cuánto tarda Brevo. No almacena códigos. Un reinicio puede perder pedidos que aún no se procesaron; el usuario puede reenviar después de la espera. Las solicitudes ya guardadas en DB y sus límites sobreviven al reinicio. No hay reintentos automáticos de correo para evitar duplicados cuando se pierde una respuesta del proveedor.

Brevo debe estar habilitado y correctamente configurado para activar recuperación. Sin ello, los endpoints responden 503. Un error de Brevo posterior al 202 se registra sin datos privados; no se revela públicamente la existencia del email.

Para VPS, configurar `REVERSE_PROXY_KNOWN_PROXIES` con la IP de Nginx **tal como la ve el contenedor** (normalmente gateway de Docker cuando Nginx está en el host). No confiar en cualquier proxy. Nginx debe pasar X-Forwarded-For y X-Forwarded-Proto. Si no se configura, se conserva el límite pero podría agrupar a varios usuarios por la IP del proxy. El límite IP es por instancia de API; los límites por cuenta son compartidos en PostgreSQL.

Actualizar el VPS es un paso separado: código, configuración privada de ese entorno y despliegue con migración. No es necesario un contenedor de correo ni una página web. No hay envío real en las pruebas automatizadas.

## Verificaciones automatizadas

- `mobile/test/recuperacion_test.dart`: navegación desde login, llamadas sin sesión, validaciones, códigos con cero inicial, reenvío bloqueado y errores de disponibilidad.
- `backend/HuellaCerca.Recuperacion.Tests`: HTTP con servidor en memoria, PostgreSQL desechable y proveedor de correo falso; incluye código/permiso vencido, concurrencia, máximo de intentos, límites, sesiones anteriores y login posterior. Ejecutar en Docker, desde el directorio backend, con conexión a PostgreSQL de pruebas y opciones de JWT/recuperación y Brevo de prueba. Crea y elimina su propia base; no usar credenciales de producción.
