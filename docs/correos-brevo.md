# Correo transaccional con Brevo

El transporte de correo y las plantillas están implementados. El flujo que los utiliza está documentado en [recuperación de contraseña](recuperacion-password.md), incluyendo endpoints, migración y pantallas Flutter. Habilitar Brevo no envía correos por sí solo.

## Configuración privada

Agregar al `.env` de la raíz del proyecto (sin reemplazar las variables existentes):

```dotenv
BREVO_ENABLED=true
BREVO_BASE_URL=https://api.brevo.com/v3/
BREVO_SENDER_EMAIL=no-reply@huellacerca.online
BREVO_SENDER_NAME=Huella Cerca
BREVO_API_KEY=REEMPLAZAR_CON_LA_CLAVE_REAL
```

El remitente debe estar autorizado en Brevo. Usar el valor secreto, no el nombre identificador de la clave. No versionar el `.env` ni compartir su contenido. El `.env` local y el del VPS son independientes. En TEST, el archivo está en `/opt/huellacerca-test/.env`.

Compose pasa estas variables a `Brevo__Enabled`, `Brevo__BaseUrl`, `Brevo__SenderEmail`, `Brevo__SenderName` y `Brevo__ApiKey` dentro del contenedor. Fuera de Compose, .NET usa estos nombres con doble guion bajo; no lee automáticamente el archivo `.env`.

Después de actualizar el código y completar los datos, desde la raíz del proyecto:

```bash
docker compose config --quiet
docker compose up -d --build huellacerca_api
```

La API valida las opciones al iniciar si `Enabled=true`. Con `false`, la app sigue funcionando y cualquier intento de envío recibe un error controlado. No imprimir `docker compose config` sin `--quiet`: puede mostrar secretos.

## Recorrido

Las plantillas se obtienen mediante `IEmailTemplates`, registrado como `EmailTemplates` en `Program.cs`.
`RecuperacionPassword(codigo)` devuelve un `ContenidoEmail` (asunto, HTML y texto simple).
El código debe ser una cadena de seis dígitos, conservando ceros iniciales.
La plantilla comunica una vigencia de diez minutos; el futuro servicio de recuperación deberá implementar ese vencimiento y el uso único. La plantilla no genera ni persiste códigos.

Ejemplo para el futuro servicio de recuperación, recibiendo ambos contratos por constructor:

```csharp
var contenido = templates.RecuperacionPassword(codigo);
await emailService.EnviarAsync(usuario.Email, contenido.Asunto,
    contenido.Html, contenido.Texto, ct);
```

Archivos de contenido:
- `CONTRACT/Email/ContenidoEmail.cs`: objeto que contiene el resultado.
- `INTERFACES/Services/IEmailTemplates.cs`: contrato para obtener plantillas.
- `SERVICES/EmailTemplates.cs`: asunto, diseño HTML y texto del correo de recuperación.

`Servicio de negocio → IEmailService.EnviarAsync → BrevoEmailService → POST https://api.brevo.com/v3/smtp/email`.

- `INTERFACES/Services/IEmailService.cs`: contrato independiente del proveedor; destinatario, asunto, HTML y texto simple.
- `INFRASTRUCTURE/Email/BrevoOptions.cs`: configuración tipada y validación.
- `INFRASTRUCTURE/Email/BrevoEmailService.cs`: arma el pedido, agrega el encabezado privado y devuelve el identificador de aceptación si está disponible.
- `API/Program.cs`: registra Options y el cliente mediante IHttpClientFactory, timeout de 20 segundos, sin redirecciones y con encabezado privado redactado.

No se reintenta automáticamente: un timeout podría ocurrir después de que el proveedor aceptó el correo. Se registran estados HTTP y resultados generales, nunca cuerpo, códigos, clave ni destinatario. Una aceptación no garantiza entrega: la comprobación real debe incluir el historial de Brevo y la casilla destinataria.

## Verificación

El proyecto `HuellaCerca.Email.Tests` usa HTTP simulado: no requiere clave ni envía correos. Cubre configuración, payload, aceptación, errores de credenciales, límites, servidor, red, timeout, cancelación y envío deshabilitado.

Desde la raíz, con Docker disponible:

```bash
docker build --target build -t huellacerca-email-check ./backend
docker run --rm huellacerca-email-check dotnet run --project HuellaCerca.Email.Tests -c Release
docker run --rm huellacerca-email-check dotnet build HuellaCerca.API -c Release --no-restore
```

La prueba real se realiza desde el flujo de recuperación con una cuenta local y un destinatario autorizado por el usuario. No se agregó un endpoint público de envío arbitrario.
